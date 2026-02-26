module mirrorlib

import log
import time
// import net.http
// import x.json2 as json

pub const session_ready_timeout := 30.0 // Time the client can take to receive a status update on the creation / joining of a session

pub enum SessionStatus {
	pending
	open
	failed
}

@[heap]
pub struct Session {
	pub:
	server           Server
	
	pub mut:
	session_code     string
	status           SessionStatus       = .pending
	conn             &Conn              = unsafe { nil }
	
	on_ready         ?fn ()
}

pub fn (mut session Session) update() {
	// Update Session connection status
	if !session.conn.is_connected {
		return
	}
	
	session.conn.package()
}

// Creates a new Session instance from a new Session on the given server
pub fn Session.new_session(server Server) !&Session {
	mut conn := Conn.new(server.ip, true)!
	
	mut session := &Session{
		server: server
		conn: conn
	}
	
	// Connect basic hooks
	conn.on_session_created = fn [mut session] (session_code string) {
		log.info("Created new session with code '${session_code}'.")
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
	log.info("User sent new session creation request to '${server.ip}'.")
	
	return session
}

// Creates a new Session instance, connected through the conn to an already-existing Session on the given server
pub fn Session.join_session(session_code string) !&Session {
	// > Find Server for session by checking suffix of code
	server := find_server_from_prefix(session_code) or {
		return error("Failed to find server from given Session Code :${err}")
	}
	
	// > Create new connection to server
	mut conn := Conn.new(server.ip, false)!
	
	// > Create Session Instance
	mut session := &Session{
		server: server
		session_code: session_code
		conn: conn
	}
	
	// > Connect session join confirmation / failiure hook
	conn.on_session_connect = fn [mut session] () {
		log.info("Session joined successfully")
		session.status = .open
		if session.on_ready != none {
			session.on_ready()
		}
	}
	
	conn.on_server_error = fn [mut session] (error string) {
		log.error("Failed to join session : ${error}")
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
	
	return session
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
