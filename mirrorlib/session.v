module mirrorlib

import time
import encoding.binary { big_endian_u64 }

import std { ByteStack }
import std.log { Log }
// import net.http
// import x.json2 as json

pub const session_ready_timeout := 30.0 // Time the client can take to receive a status update on the creation / joining of a session
pub const nid_request_timeout := 20.0

pub enum SessionStatus {
	pending
	open
	failed
}

@[heap]
pub struct Session {
	pub:
	server                    Server
	
	pub mut:
	session_code              string
	status                    SessionStatus        = .pending
	conn                      &Conn                = unsafe { nil }
	log                       &Log                 = unsafe { nil }
	
	on_ready                  ?fn ()
	can_update                bool                 = true
	
	on_packet_create          ?fn (nid u64, data []u8)
	on_packet_update          ?fn (nid u64, data []u8)
	on_packet_delete          ?fn (nid u64, data []u8)
	on_packet_lock            ?fn (nid u64, data []u8)
	on_packet_unlock          ?fn (nid u64, data []u8)
}

pub fn (mut session Session) update() {
	// Update Session connection status
	if !session.conn.is_connected || !session.can_update {
		return
	}
	
	session.conn.package()
}

// Creates a new Session instance from a new Session on the given server
pub fn Session.new_session(server Server, mut logger Log) !&Session {
	mut conn := Conn.new(server.ip, true, mut logger)!
	
	mut session := &Session{
		server: server
		conn: conn
		log: logger
	}
	
	// Connect basic hooks
	conn.on_session_created = fn [mut logger, mut session] (session_code string) {
		logger.info("Created new session with code '${session_code}'.")
		session.session_code = session_code
		session.status = .open
		if session.on_ready != none {
			session.on_ready()
		}
	}
	
	// Send new session request
	create_session_packet := Packet.empty(action_create_session)
	conn.send_packet(create_session_packet) or { return error("Failed to join create-session-packet : ${err}") }
	
	// Log
	logger.info("User sent new session creation request to '${server.ip}'.")
	
	// TODO : Await createion here
	
	session.init_hooks()
	
	return session
}

// Creates a new Session instance, connected through the conn to an already-existing Session on the given server
pub fn Session.join_session(session_code string, mut logger Log) !&Session {
	// > Find Server for session by checking suffix of code
	server := find_server_from_prefix(session_code) or {
		return error("Failed to find server from given Session Code :${err}")
	}
	
	// > Create new connection to server
	mut conn := Conn.new(server.ip, false, mut logger)!
	
	// > Create Session Instance
	mut session := &Session{
		server: server
		session_code: session_code
		conn: conn
		log: logger
	}
	
	// > Connect session join confirmation / failiure hook
	conn.on_session_connect = fn [mut logger, mut session] () {
		logger.info("Session joined successfully")
		session.status = .open
		if session.on_ready != none {
			session.on_ready()
		}
	}
	
	conn.on_server_error = fn [mut logger, mut session] (error string) {
		logger.failed("Failed to join session : ${error}")
		session.status = .failed
	}
	
	// > Send join session request
	join_session_packet := Packet{action: action_join_session, data: session_code.bytes()}
	conn.send_packet(join_session_packet) or { return error("Failed to send join-session-packet : ${err}") }
	
	// > Wait for the Server to respond to the Session Join request, return an errror if this fails
	session.wait_until_ready() or {
		return error("Joining the Session timed out")
	}
	
	if session.status == .failed {
		return error("Failed to join session.")
	}
	
	session.init_hooks()
	
	return session
}


pub fn (mut session Session) on_packet(packet Packet) {
	if packet.data.len < 8 { return }
	mut bytes := ByteStack(packet.data.clone())
	nid := bytes.pop_u64()
	match packet.action {
		action_element_create {
			if session.on_packet_create != none {
				session.on_packet_create(nid, bytes)
			}
		}
		action_element_update {
			if session.on_packet_update != none {
				session.on_packet_update(nid, bytes)
			}
		}
		action_element_delete {
			if session.on_packet_delete != none {
				session.on_packet_delete(nid, bytes)
			}
		}
		action_element_lock {
			if session.on_packet_lock != none {
				session.on_packet_lock(nid, bytes)
			}
		}
		action_element_unlock {
			if session.on_packet_unlock != none {
				session.on_packet_unlock(nid, bytes)
			}
		}
		else {  }
	}
}

pub fn (mut session Session) send_packet(packet Packet) {
	session.conn.send_packet(packet) or {
		session.log.failed("Failed to send packet '${packet.action}' from Session : ${err}")
	}
}


// Returns true, if the (doesn't send/receive additional packets to the Session)
pub fn (session Session) is_host() bool {
	return session.conn.is_host
}


// Waits on this thread until the status of the session is not pending or until a timeout is reached (returns an error on timeout)
pub fn (mut session Session) wait_until_ready() ! {
	sw := time.new_stopwatch()
	for {
		// > Return error on timeout
		if sw.elapsed().seconds() > session_ready_timeout {
			return error("Session ready await timed out after '${session_ready_timeout}' seconds.")
		}
		
		session.conn.package()
		
		if session.status != .pending {
			log.info("Connection properly registered on server - Connection established.")
			break
		}
	}
}

pub fn (mut session Session) init_hooks() {
	if session.conn == unsafe { nil } {
		log.failed("Can't initiaize connection hooks at the moment : Connection no initialized")
		return
	}
	
	session.conn.on_packet = session.on_packet
}

// Asks the Server for a new Network ID, waits for a response and returns that (times out after ```nid_request_timeout``` seconds)
pub fn (mut session Session) get_new_nid() !u64 {
	// > Send new-nid request
	session.can_update = false
	defer {
		session.can_update = true
	}
	
	session.conn.send_packet(Packet.empty(action_new_nid)) or {
		return error("Failed to send new-nid request packet : ${err}")
	}
	
	// > Wait for repsonse
	nid_packet := session.conn.await_packet_by_action(action_new_nid, nid_request_timeout) or {
		return error("Waiting for new NID from server timed out : ${err}")
	}
	
	nid := big_endian_u64(nid_packet.data)
	println("New NID received : ${nid}")
	
	// > Return new NID
	return nid
}


// ======== UTIL ========

// Returns a server instance matching the given code by reading the suffix of the given session code
pub fn find_server_from_prefix(code string) !Server {
	if !code.contains("-") {
		return error("Invalid Session Code given : Session Code must contain suffix, seperated by '-', which indicates the Session's Host Server")
	}
	suffix := code.all_after_last("-").to_lower()
	servers := Server.fetch_server_list() or {
		return error("Failed to fetch list of servers")
	}
	for server in servers {
		if server.key == suffix {
			return server
		}
	}
	return error("Server with key '${suffix}' not found.")
}

// ======== NID ========

pub fn (mut session Session) mirror_new_nid(nid &NID) {
	// WARN : This may lead to duplicate creation (not reeeally a problem)
}

pub fn (mut session Session) mirror_delete_nid(nid &NID) {
	// WARN : This may lead to the deletion of already-deleted NIDs (not really a problem)
}

pub fn (mut session Session) mirror_update_nid(nid &NID) {
	// WARN : This may lead to race conditions beacause of how the upadtes for each connection is handeled seperately
	// (not a problem, since only backlog is filled in parrallel, but packaging is handeled one after the other) -> Last update in session tick always wins
}

pub fn (mut session Session) mirror_lock_nid(nid &NID, on_lock_fail fn (failed_nid &NID)) {
	// WARN : This may lead to locking of already locked NIDs
}

pub fn (mut session Session) mirror_unlock_nid(nid &NID) {
	// WARN : This may lead to unlocking of already unlocked NIDs
}

// TODO : Session joining on server side
// TODO : All NID functionality here
