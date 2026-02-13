module mirrorlib

import log
import net
import net.http
import crypto.scrypt { scrypt }
import encoding.binary { little_endian_get_u32, little_endian_u32 }

pub const server_port              := 6666 // < Spooky (*-*)
pub const max_tcp_bytes_read       := int(max_u16)
pub const tcp_read_buffer_size     := int(max_u16)
pub const max_packets_per_update   := 16
pub const internal_actions         := [u32(1)]

@[heap]
pub struct Conn {
	pub mut:
	is_connected             bool
	session_hash             []u8
	user_id                  u32
	
	tcp                      &net.TcpConn
	
	// Hooks
	pub:
	on_packet                ?fn (packet Packet)
	on_session_connect       ?fn (user_id u32)
	on_session_disconnect    ?fn ()
	
	mut:
	backlog                  []u8
}

pub fn (mut conn Conn) connect_to_session(server_ip string, session_code string) ! {
	// Fetch current session salt of server
	api_result := http.get("http://api.lemonjam.com/salt?server=${server_ip}") or { return error("Failed to fetch server salt from API : ${err}") }
	server_salt := api_result.body.bytes() // > Server accepts hashes salted from current or last salt to avoid a race condition
	
	// Dial Server Adress
	ip, _ := net.split_address(server_ip) or { return error("Failed to split given ip adress '${server_ip}' by ip and port : ${err}") }
	conn.tcp = net.dial_tcp("${ip}:${server_port}") or { return error("Failed to dial tcp connection : ${err}") }
	conn.tcp.sock.set_option_int(.receive_buf_size, tcp_read_buffer_size) or { return error("Failed to set buffer size for TCP Connection : ${err}") }
	
	// Hash Session Code to compare with server
	hashed_session := scrypt(session_code.bytes(), server_salt, 32, 8, 4, 16) or { return error("Failed to hash session code : ${err}") }
	conn.session_hash = hashed_session
	
	// Send connection verification hash to server
	conn.tcp.write(Packet{action_join_session_hash, hashed_session}.to_byte_arr()) or { return error("Failed to send session hash to server : ${err}") }
	
	log.info("User sent connection request to server '${server_ip}' with session code '${session_code}'")
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
}

// Updates packet receiving and calls the on_packet function, if a packet is received
pub fn (mut conn Conn) update() ! {
	if !conn.is_connected {
		return
	}
	
	// Collect data in buffer and merge with backlog
	mut buf := []u8{len: max_tcp_bytes_read}
	new_bytes := conn.tcp.read(mut buf) or { return error("Failed to read data from TCP Connection : ${err}") }
	if buf.len == 0 {
		return
	}
	
	buf.trim(new_bytes)
	conn.backlog << buf
	
	// Package available data
	for i in 0..max_packets_per_update {
		if conn.backlog.len < 8 { break }
		
		// > Get base Packet data (length and action)
		packet_len := little_endian_u32(conn.backlog)
		if conn.backlog.len < packet_len {
			break
		} else {
			for _ in 0..4 { _ := conn.backlog.pop_left() }
		}
		
		raw_packet_action := pop_left_many(mut conn.backlog, 4) or {
			log.error("Failed to properly parse connection backlog to read next packet action!")
			break
		}
		packet_action := little_endian_u32(raw_packet_action)
		
		data := pop_left_many(mut conn.backlog, int(packet_len) - 8) or {
			log.error("Failed to properly parse connection backlog to read packet data!")
			break
		}
		
		// > Construct Packet and call on_packet hook
		packet := Packet{action: packet_action, data: data}
		if packet_action in internal_actions {
			conn.on_packet_internal(packet)
		} else {
			if conn.on_packet != none {
				conn.on_packet(packet)
			}
		}
		
		// > Return error on insufficient loop size to handle backlog
		if i == max_packets_per_update - 1 {
			log.warn("Backlog is to big! Amount of packets to construct exceeds maximum packet constructions per update (${max_packets_per_update} / update)")
		}
	}
	
	// Warn, if backlog of data exceed certain threshold
	log.warn("Connection data backlog is exceeding maximum readable bytes per update (${max_tcp_bytes_read} / update)!")
}

// Used to handle internal non-app-specific packets to keep the connection up (heartbeat, reconnection, etc.)
fn (mut conn Conn) on_packet_internal(packet Packet) {
	match packet.action {
		// Call hook for session join and activate active session mode
		action_user_connected {
			conn.user_id = little_endian_u32(packet.data)
			if conn.on_session_connect != none {
				conn.on_session_connect(conn.user_id)
			}
			conn.is_connected = true
		}
		else {  }
	}
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

