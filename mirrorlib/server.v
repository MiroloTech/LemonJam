module mirrorlib

import os
import log
import x.json2 as json

pub enum ServerStatus {
	offline
	live
	maintenance
	coming_soon
}

@[heap]
pub struct Server {
	pub:
	key       string
	title     string
	ip        string
	lat       f64
	lon       f64
	
	pub mut:
	status    ServerStatus
	ping      f64                   = -1.0       // ms
}


pub fn Server.load_list_from_json(data string) ![]Server {
	raw_data := json.decode[json.Any](data) or { return error("Failed to parse json : ${err}") }
	mut servers := []Server{}
	for key, raw_server_data in raw_data.as_map() {
		server_data := raw_server_data.as_map()
		title := server_data["title"]    or { return error("Invalid server data : Missing 'title' data") }
		ip    := server_data["ip"]       or { return error("Invalid server data : Missing 'ip' data") }
		lat   := server_data["lat"]      or { return error("Invalid server data : Missing 'lat' data") }
		lon   := server_data["lon"]      or { return error("Invalid server data : Missing 'lon' data") }
		status:= server_data["status"]   or { return error("Invalid server data : Missing 'status' data") }
		server := Server{
			key: key
			title: title.str()
			ip: ip.str()
			lat: lat.f64()
			lon: lon.f64()
			status: match status.str() {
				"offline" { .offline }
				"live" { .live }
				"maintenance" { .maintenance }
				"coming-soon" { .coming_soon }
				else { return error("Invalid server data : Invalid server status '${status}'") }
			}
		}
		servers << server
	}
	return servers
}

pub fn (mut server Server) update_ping() {
	if server.status != .live { return }
	result := os.execute("ping -i 20 ${server.ip}")
	if result.output.contains("Average = ") {
		server.ping = result.output.find_between("Average = ", "ms").f64()
	} else {
		log.error("Ping to ${server.ip} server '${server.title}' failed : ${result.output}")
		return
	}
	
	// TODO : Send custom ping packet to server with mirrorlib
}
