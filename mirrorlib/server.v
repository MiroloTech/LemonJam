module mirrorlib

import os
import std.log
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


pub fn (mut server Server) refresh_ping() {
	if server.status != .live { return }
	result := os.execute("ping ${server.ip}")
	if result.output.contains("Average = ") { // TODO : Make this better to suit non-englisch PCs too
		server.ping = result.output.find_between("Average = ", "ms").f64()
	} else {
		log.failed("Ping to ${server.ip} server '${server.title}' failed : ${result.output}")
		return
	}
	
	// TODO : Send custom ping packet to server with mirrorlib
}

fn Server.load_list_from_json(data string) ![]Server {
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

// WARNING : This is temporary debug list for the existing servers, where the Antartic Server is localhost
pub fn Server.fetch_server_list() ![]Server {
	// TODO : Maybe implement caching for this list
	// TODO : Internet logic here
	println(os.args)
	temp := '{
    "ts": {
        "title": "Test",
        "status": "live",
        "ip": "127.0.0.1",
        "lon": 142.0,
        "lat": -81.3
    },
    "de": {
        "title": "Germany",
        "status": "live",
        "ip": "${os.args[1] or { "127.0.0.1" }}",
        "lon": 9.1,
        "lat": 48.8
    },
    "au": {
        "title": "Australia",
        "status": "live",
        "ip": "185.15.59.226",
        "lon": 150.7,
        "lat": -33.7
    },
    "us": {
        "title": "United States",
        "status": "live",
        "ip": "140.82.121.3",
        "lon": -121.2,
        "lat": 37.7
    },
    "as": {
        "title": "China",
        "status": "live",
        "ip": "151.101.65.140",
        "lon": 121.1,
        "lat": 31.1
    },
    "br": {
        "title": "Brazil",
        "status": "offline",
        "ip": "142.250.185.174",
        "lon": -38.7,
        "lat": -12.8
    }
}'
	servers := Server.load_list_from_json(temp) or {
		return error("Failed to parse list of existing servers : ${err}")
	}
	return servers
}
