module mirrorlib

import net
import log

@[heap]
pub struct Client {
	pub:
	is_server         bool //              = false
	
	mut:
	conn              Conn
	
	pub mut:
	user_data         voidptr           = unsafe { nil }
	on_packet         ?FnOnPacket
}


pub fn Client.init(server_ip string, data_port u32, user_data voidptr, on_packet ?FnOnPacket) !&Client {
	// Create ip and connect to server
	ip6 := if server_ip.contains(":") { "[${server_ip}]:${data_port}" } else { "${server_ip}:${data_port}" }
	mut tcp := net.dial_tcp(ip6) or { return error("Failed to dial ip '${ip6}' : ${err}") }
	mut conn := Conn.new(mut tcp, user_data, on_packet)
	log.info("Connection successfully made to ${conn.get_ip()}")
	
	// Start conection update loop
	go conn.update()
	
	// Create client instance
	return &Client{
		conn: conn
		user_data: user_data
		on_packet: on_packet
	}
}

pub fn (mut client Client) send_packet(packet Packet) {
	go fn [mut client] (packet Packet) {
		client.conn.send_packet(packet) or {
			log.warn("Failed to send packet from client to server : ${err}")
			return
		}
	}(packet)
}

// Closes current connection
pub fn (mut client Client) close() ! {
	client.conn.close() or {
		log.error("Failed to close local client connection : ${err}")
		return
	}
}
