module mirrorlib

import net
import log
import sync

@[heap]
pub struct Server {
	pub:
	is_server      bool                 = true
	
	mut:
	conns          map[int]&Conn
	next_conn_id   int
	listener       &net.TcpListener
	mutex          sync.Mutex          // TODO : Implement mutex for server
	
	pub mut:
	user_data      voidptr              = unsafe { nil }
	on_packet      ?FnOnPacket
	
	// TODO : Add on_client_connect
}

pub fn Server.init(user_data voidptr, on_packet ?FnOnPacket) !&Server {
	// > Initialize listener
	mut listener := net.listen_tcp(.ip6, ":${listener_port}", dualstack: true) or { return error("Failed to open listener for new TCP Connections : ${err}") }
	listener.is_blocking = false // Probably useless but whatever
	
	conns := map[int]&Conn{}
	
	mut server := &Server{
		listener: listener
		conns: conns
		
		user_data: user_data
		on_packet: on_packet
	}
	
	go server.handle_listener()
	return server
}

// Handles all the users, that request a connection
pub fn (mut server Server) handle_listener() {
	for {
		// > Accept new TCP connection if available
		// mut listener := net.listen_tcp(.ip, "127.0.0.1:${listener_port}", dualstack: true) or { return }
		// listener.is_blocking = false
		
		// Accept any new connection
		mut tcp := server.listener.accept() or { return }
		// tcp.set_read_timeout(1000)
		mut conn := Conn.new(mut tcp, server, on_mirror_packet)
		
		// Write new connection to list of connections
		server.mutex.@lock()
		println("Connections locked for adding a new connection")
		
		id := server.next_conn_id
		server.next_conn_id += 1
		server.conns[id] = conn
		
		server.mutex.unlock()
		log.info("Net Connection made : ${conn.get_ip()}")
		
		// Start Update loop
		go conn.update()
	}
}

fn on_mirror_packet(packet Packet, user_data voidptr, origin string) {
	mut server := unsafe { &Server(user_data) }
	log.info("Package received from '${origin}' : ${packet.text_str()}")
	
	// Send mirrored packet on seperate threads
	go fn [mut server] (packet Packet, origin string) {
		server.mutex.@lock()
		defer { server.mutex.unlock() }
		// Send packet to every other connection that is not the original connection
		for _, mut conn in server.conns {
			// log.info("Checking mirror at '${conn.get_ip()}'...")
			if conn.get_ip() == origin { continue } // > Don't send packet to original user
			conn.send_packet(packet) or {
				log.warn("Failed to send mirror through server to other connections : ${err}")
				continue
			}
		}
		
		// React to packet on server side
		if server.on_packet != none {
			server.on_packet(packet, server.user_data, origin)
		}
	}(packet, origin)
}

pub fn (mut server Server) send_packet(packet Packet) {
	println("Sending packet")
	// Lock server connection list
	server.mutex.@lock()
	defer { server.mutex.unlock() }
	
	// Send packet on seperate threads
	go fn [mut server] (packet Packet) {
		// Send packet to every connection
		for _, mut conn in server.conns {
			conn.send_packet(packet) or {
				log.warn("Failed to send packet from server to other connections : ${err}")
				continue
			}
			println("Packet sent")
		}
		
		println("Packet sending process finished")
	}(packet)
}

// Closes every connection that the server has
pub fn (mut server Server) close() ! {
	server.mutex.@lock()
	defer { server.mutex.unlock() }
	
	for _, mut conn in server.conns {
		conn.close() or {
			log.error("Failed to close connection at '${conn.get_ip()}' : ${err}")
			continue
		}
	}
	server.conns.clear()
	
	server.listener.close() or {
		log.warn("Failed to close server connection listener : ${err}")
		return
	}
}
