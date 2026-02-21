module app

import log
// import net.http
// import x.json2 as json

import mirrorlib { Server, Conn }

@[heap]
pub struct Session {
	pub:
	server        Server
	
	pub mut:
	session_code  string
	is_open       bool
	conn          &Conn              = unsafe { nil }
}

pub fn Session.new(server Server) !&Session {
	mut session := &Session{
		server: server
		conn: Conn.new(server.ip)!
	}
	
	// > Connect basic hooks
	session.conn.on_session_created = fn [mut session] (session_code string) {
		log.info("Created new session with code '${session_code}'.")
		session.session_code = session_code
		session.is_open = true
	}
	
	return session
}


pub fn (mut session Session) start_new_session() ! {
	session.conn.start_new_session(session.server.ip) or { return error("Failed to start new session : ${err}") }
	
	/*
	// Connect to server
	session.conn.connect_to_session(session.server.ip, session_code) or { return error("Failed to connect to session") }
	*/
}

pub fn (mut session Session) update() {
	// Update Session connection status
	if !session.conn.is_connected {
		return
	}
	
	session.conn.package()
	
	/*
	if session.conn.last_packet.action == mirrorlib.action_session_code_confirmation {
		session.is_open = true
		session.session_code = session.conn.last_packet.data.bytestr()
		println("NEW SESSION CODE : ${session.session_code}")
	}
	*/
}

