module mirrorlib

import net
import log
import sync

pub const listener_port := 8080

pub type FnOnPacket = fn (packet Packet, user_data voidptr, origin string)

@[heap]
pub struct Conn {
	mut:
	backlog          []u8            = []u8{}
	tcp              &net.TcpConn    = unsafe { nil }
	mutex            sync.Mutex
	
	pub mut:
	user_data        voidptr         = unsafe { nil }
	on_packet        ?FnOnPacket
	is_closed        bool
}

pub fn Conn.new(mut tcp &net.TcpConn, user_data voidptr, on_packet ?FnOnPacket) &Conn {
	return &Conn{
		backlog: []u8{}
		tcp: tcp
		user_data: user_data
		on_packet: on_packet
	}
}

pub fn (conn Conn) get_ip() string {
	addr := conn.tcp.addr() or { return "" }
	return "${addr}"
	// return conn.tcp.peer_ip() or { "" }
}

pub fn (mut conn Conn) update() {
	// log.warn("Failed to properly update connection to '${conn.get_ip()}' : ${err}")
	for {
		println("Connection updating...")
		
		// Read data with backlog prepended
		mut temp := []u8{len: 1024}
		byte_count := conn.tcp.read(mut temp) or { break }
		if byte_count == 0 { return }
		temp.trim(byte_count)
		
		println("Done reading data...")
		/*
		if byte_count > 0 {
			log.info("${byte_count} bytes read")
			log.info("${temp}")
		}
		*/
		
		mut conn_data := conn.backlog.clone()
		conn_data << temp
		
		// Clear backlog
		conn.backlog.clear()
		
		// Format into data packets
		if conn_data.len == 0 { return }
		
		mut tries := 20
		for conn_data.len >= 8 {
			if tries == 0 {
				log.warn("Exceeded the amount of tries to parse data '${conn_data}' to packet")
				break
			}
			len := u32(conn_data[0]) << u32(24) | u32(conn_data[1]) << u32(16) | u32(conn_data[2]) << u32(8) | u32(conn_data[3])
			act := u32(conn_data[4]) << u32(24) | u32(conn_data[5]) << u32(16) | u32(conn_data[6]) << u32(8) | u32(conn_data[7])
			mut data := []u8{}
			
			println("Parsing data from connection '${conn_data}'")
			
			// > Check, if packet is complete
			if conn_data.len >= len {
				data = conn_data[8..len].clone()
				packet := Packet{
					action: act
					data: data
				}
				if conn.on_packet != none {
					conn.on_packet(packet, conn.user_data, conn.get_ip())
					log.info("Packet received")
				}
				
				// > Clear out data
				conn_data.drop(int(len))
				continue
			} else {
				break
			}
			tries -= 1
		}
		
		// Fill in rest of backlog
		conn.backlog << conn_data
		
		println("Done parsing")
		
		// conn.tcp.wait_for_read() or {  }
	}
	conn.close() or { log.error("Failed to close connection in update loop : ${err}") }
}

pub fn (mut conn Conn) send_packet(packet Packet) ! {
	conn.mutex.@lock()
	defer { conn.mutex.unlock() }
	if conn.is_closed {
		return error("Can't send packet through previously closed connection")
	}
	
	conn.tcp.write(packet.to_byte_arr()) or { return error("Failed to send packet '${packet.action}' to Conn '${conn.get_ip()}' : ${err}") }
	log.info("Packet sent")
}

pub fn (mut conn Conn) close() ! {
	conn.mutex.@lock()
	defer { conn.mutex.unlock() }
	
	if conn.is_closed { return }
	conn.tcp.close()!
	conn.is_closed = true
}
