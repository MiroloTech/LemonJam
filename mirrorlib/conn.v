module mirrorlib

import log
import net
import time
// import net.http
// import crypto.scrypt { scrypt }
import encoding.binary { big_endian_u32 }

pub const server_port              := 6786
pub const max_tcp_bytes_read       := int(max_u16)
pub const tcp_read_buffer_size     := int(max_u16)
pub const max_packets_per_update   := 16
pub const conn_registry_timeout    := 5.0

@[heap]
pub struct Conn {
	pub mut:
	is_connected             bool
	session_code             string
	server_ip                string
	
	tcp                      &net.TcpConn
	
	// Hooks
	on_packet                ?fn (packet Packet)
	on_session_created       ?fn (session_code string)
	on_session_connect       ?fn ()
	on_session_disconnect    ?fn ()
	
	// Used internally to avoid connection and disconnection of the on_packet hook (Note, that this skips all but the last packet, when backlog includes more than one packet)
	last_packet              Packet             = Packet.empty(0)
	
	mut:
	backlog                  shared []u8
}

// Returns a new connection instance (not active)
pub fn Conn.new(target_ip string) !&Conn {
	server_ip := (if target_ip.contains(":") { target_ip.all_before(":") } else { target_ip }) + ":${server_port}"
	
	// Connect to server
	mut tcp := net.dial_tcp(server_ip) or { return error("Failed to connect to server under ip ${server_ip} : ${err}") }
	mut conn := &Conn{
		server_ip: server_ip
		is_connected: false
		tcp: tcp
	}
	go conn.update_routine()
	
	// Wait for server to send connection confirmation package
	sw := time.new_stopwatch()
	for {
		// > Return error on timeout
		if sw.elapsed().seconds() > conn_registry_timeout {
			return error("Server Registry Package awaital timed out after '${conn_registry_timeout}' seconds.")
		}
		
		conn.package()
		
		if conn.last_packet.action == action_user_connected {
			log.info("Connection properly registered on server - Connection established.")
			break
		}
	}
	conn.is_connected = true
	
	// Return properly instantiated and registered Connection instance
	return conn
}


fn (mut conn Conn) heartbeat() {
	if !conn.is_connected {
		return
	}
	
	conn.send_packet(Packet.empty(action_heartbeat)) or {  }
}

pub fn (mut conn Conn) send_packet(packet Packet) ! {
	if !conn.is_connected {
		return error("Can't send packet. Connection isn't active.")
	}
	
	conn.tcp.write(packet.to_byte_arr()) or { return error("Failed to write packet to tcp connection") }
	println("Packet sent : ${packet}")
}

// Updates packet receiving and calls the on_packet function, if a packet is received

pub fn (mut conn Conn) package() {
	lock conn.backlog {
		for i in 0..max_packets_per_update {
			if conn.backlog.len < 8 { break }
			
			// > Get base Packet data (length and action)
			packet_len := big_endian_u32(conn.backlog)
			if conn.backlog.len < packet_len {
				break
			} else {
				for _ in 0..4 { _ := conn.backlog.pop_left() }
			}
			
			raw_packet_action := pop_left_many(mut conn.backlog, 4) or {
				log.error("Failed to properly parse connection backlog to read next packet action!")
				break
			}
			packet_action := big_endian_u32(raw_packet_action)
			
			data := pop_left_many(mut conn.backlog, int(packet_len) - 8) or {
				log.error("Failed to properly parse connection backlog to read packet data!")
				break
			}
			
			// > Construct Packet and call on_packet hook
			packet := Packet{action: packet_action, data: data}
			println("New packet : ${packet}")
			if conn.on_packet != none {
				conn.on_packet(packet)
			}
			if packet.action in internal_actions {
				conn.on_packet_internal(packet)
			}
			conn.last_packet = packet
			
			// > Return error on insufficient loop size to handle backlog
			if i == max_packets_per_update - 1 {
				log.warn("Backlog is too big! Amount of packets to construct exceeds maximum packet constructions per update (${max_packets_per_update} / update)")
			}
		}
	}
	
	// Warn, if backlog of data exceed certain threshold
	if conn.backlog.len > max_tcp_bytes_read {
		log.warn("Connection data backlog is exceeding maximum readable bytes per update (${max_tcp_bytes_read} / update)!")
	}
}

pub fn (mut conn Conn) update_routine() ! {
	for {
		// Collect data in buffer and merge with backlog
		mut buf := []u8{len: max_tcp_bytes_read}
		new_bytes := conn.tcp.read(mut buf) or {
			// return error("Failed to read data from TCP Connection : ${err}")
			// log.error("Failed to read data from TCP Connection : ${err}")
			continue
		}
		
		
		buf.trim(new_bytes)
		lock conn.backlog {
			conn.backlog << buf
		}
	}
}



// Used to handle internal non-app-specific packets to keep the connection up (heartbeat, reconnection, etc.)
fn (mut conn Conn) on_packet_internal(packet Packet) {
	match packet.action {
		// Call hook for session join and activate active session mode
		action_session_code_confirmation {
			conn.session_code = packet.data.bytestr()
			if conn.on_session_created != none {
				conn.on_session_created(conn.session_code)
			}
			conn.is_connected = true
			log.info("User connected successfully to Session '${conn.session_code}'.")
		}
		else {  }
	}
}


// ========== CONNECTION ==========

// Creates a new connection on the given server
pub fn (mut conn Conn) start_new_session(target_ip string) ! {
	// Send new session request
	packet := Packet.empty(action_create_session)
	conn.send_packet(packet) or { return error("Failed to write packet '${packet.action}' to tcp connection : ${err}") }
	
	// Log
	log.info("User sent new session creation request to '${target_ip}'.")
}


// ========== UTILLITY ==========

// Pops n bytes from the left of the buffer
fn pop_left_many(mut buf []u8, n int) ![]u8 {
	mut out := []u8{}
	if n > buf.len {
		return error("Can't pop left many from array : Pop count exceeds array length : ${n} > ${buf.len}")
	}
	for _ in 0..n {
		out << buf.pop_left()
	}
	return out
}

