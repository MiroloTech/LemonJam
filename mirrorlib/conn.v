module mirrorlib

import std.log { Log }
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

pub type PacketHook = fn (packet Packet)

@[heap]
pub struct Conn {
	pub mut:
	is_connected             bool
	// server_ip                string
	
	log                      &Log               = unsafe { nil }
	tcp                      &net.TcpConn       = unsafe { nil }
	
	// Hooks
	on_packet                ?fn (packet Packet)
	on_session_created       ?fn (session_code string)
	on_session_connect       ?fn ()
	on_session_disconnect    ?fn ()
	on_server_error          ?fn (msg string)
	
	packet_hooks             map[u32][]PacketHook
	
	// Used internally to avoid connection and disconnection of the on_packet hook (Note, that this skips all but the last packet, when backlog includes more than one packet)
	last_packet              Packet             = Packet.empty(0)
	
	mut:
	backlog                  shared []u8
	
	pub:
	is_host                  bool
}

// Returns a new connection instance (not active)
pub fn Conn.new(target_ip string, is_host bool, mut logger Log) !&Conn {
	server_ip := (if target_ip.contains(":") { target_ip.all_before(":") } else { target_ip }) + ":${server_port}"
	
	// Connect to server
	mut tcp := net.dial_tcp(server_ip) or { return error("Failed to connect to server under ip ${server_ip} : ${err}") }
	mut conn := &Conn{
		is_connected: false
		tcp: tcp
		is_host: is_host
		log: logger
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
	// conn.log.debug("Packet sent : ${packet}")
	conn.log.tcp_out(packet)
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
				log.failed("Failed to properly parse connection backlog to read next packet action!")
				break
			}
			packet_action := big_endian_u32(raw_packet_action)
			
			data := pop_left_many(mut conn.backlog, int(packet_len) - 8) or {
				log.failed("Failed to properly parse connection backlog to read packet data!")
				break
			}
			
			// > Construct Packet and call on_packet hook
			packet := Packet{action: packet_action, data: data}
			conn.react_to_packet(packet)
			
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
			// log.failed("Failed to read data from TCP Connection : ${err}")
			continue
		}
		
		
		buf.trim(new_bytes)
		lock conn.backlog {
			conn.backlog << buf
		}
	}
}


// Internal reaction-function to new packets
fn (mut conn Conn) react_to_packet(packet Packet) {
	// conn.log.debug("New packet : ${packet}")
	conn.log.tcp_in(packet)
	
	// > Call base hook for all packets
	if conn.on_packet != none {
		conn.on_packet(packet)
	}
	
	// > Call packet-action-specific hook
	if packet.action in conn.packet_hooks.keys() {
		for hook in conn.packet_hooks[packet.action] {
			hook(packet)
		}
	}
	
	// > Trigger an internal packet reaction
	if packet.action in internal_actions {
		conn.on_packet_internal(packet)
	}
	
	// > Re-/Define last packet on connection
	conn.last_packet = packet
}


// Used to handle internal non-app-specific packets to keep the connection up (heartbeat, reconnection, etc.)
fn (mut conn Conn) on_packet_internal(packet Packet) {
	match packet.action {
		// Call hook for session join and activate active session mode
		action_session_code_confirmation {
			session_code := packet.data.bytestr()
			if conn.on_session_created != none {
				conn.on_session_created(session_code)
			}
			conn.is_connected = true
			log.info("User connected successfully to Session '${session_code}'.")
		}
		action_session_join_confirmation {
			log.info("USer joining session confirmed")
			if conn.on_session_connect != none {
				conn.on_session_connect()
			}
			conn.is_connected = true
		}
		action_server_error {
			if conn.on_server_error != none {
				conn.on_server_error(packet.data.bytestr())
			}
		}
		else {  }
	}
}

// Freezes frame until a packet with the given action is received, which is then returned, or the request times out after ```timeout``` seconds
pub fn (mut conn Conn) await_packet_by_action(action u32, timeout f64) !Packet {
	// > Create stop watch for timeout
	sw := time.new_stopwatch()
	conn.last_packet = Packet.empty(0)
	
	// > Wait and re-package incoming data until packet with action is received or loop times out
	for {
		// > Return error on timeout
		if sw.elapsed().seconds() > timeout {
			return error("Awaital for packet with action '${action}' timed out after ${timeout} sec.")
		}
		
		conn.package()
		
		// TODO : Implement stack feature to not be limited by the 'last packet' per packaging command (multiple packets might be made during one ```package``` call)
		if conn.last_packet.action == action {
			return conn.last_packet
		}
	}
	return error("Awaital for packet with action '${action}' timed out after ${timeout} sec.")
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

