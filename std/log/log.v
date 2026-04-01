module log

import term
import time
import net.http

const log_all_to_term := $d("log-all-to-term", true)
const log_file_name := "net_session.log"

pub enum NetLogType {
	debug
	error
	http_request
	http_response
	tcp_in
	tcp_out
}

pub struct LogTcp {
	pub:
	action u32
	data []u8
}

pub interface LogPacket {
	mut:
	action u32
	data []u8
}

pub type LogDebug = string
pub type LogInfo = string
pub type LogError = string
pub type LogHttpRequest = string | http.Request
pub type LogHttpResponse = http.Response
pub type LogTcpIn = LogTcp
pub type LogTcpOut = LogTcp
pub type LogData = LogDebug | LogInfo | LogError | LogHttpRequest | LogHttpResponse | LogTcpIn | LogTcpOut

@[heap]
pub struct Log {
	pub mut:
	entries         []LogData
	on_new_entry    ?fn (entry LogData)
}

pub fn (mut log Log) debug(entry LogDebug) {
	log.entries << entry
	if log.on_new_entry != none { log.on_new_entry(entry) }
	if log_all_to_term { debug(entry) }
}

pub fn (mut log Log) info(entry LogInfo) {
	log.entries << entry
	if log.on_new_entry != none { log.on_new_entry(entry) }
	if log_all_to_term { info(entry) }
}

pub fn (mut log Log) failed(entry LogError) {
	log.entries << entry
	if log.on_new_entry != none { log.on_new_entry(entry) }
	if log_all_to_term { failed(entry) }
}

pub fn (mut log Log) http_request(entry LogHttpRequest) {
	log.entries << entry
	if log.on_new_entry != none { log.on_new_entry(entry) }
	if log_all_to_term {
		if entry is string {
			debug("Http Request : ${entry}")
		} else if entry is http.Request {
			debug("Http Request : ${entry.url}")
		}
	}
}

pub fn (mut log Log) http_response(entry LogHttpResponse) {
	log.entries << entry
	if log.on_new_entry != none { log.on_new_entry(entry) }
	if log_all_to_term {
		debug("Http Response : ${entry.body}")
	}
}

pub fn (mut log Log) tcp_in(entry LogPacket) {
	packet := LogTcpIn{action: entry.action, data: entry.data}
	log.entries << packet
	if log.on_new_entry != none { log.on_new_entry(packet) }
	if log_all_to_term {
		debug("New Packet : ${entry}")
	}
}

pub fn (mut log Log) tcp_out(entry LogPacket) {
	packet := LogTcpOut{action: entry.action, data: entry.data}
	log.entries << packet
	if log.on_new_entry != none { log.on_new_entry(packet) }
	if log_all_to_term {
		debug("Packet sent : ${entry}")
	}
}



pub fn debug(s string) {
	print(term.white("[${get_log_time()}] "))
	println(term.gray(s))
}

pub fn info(s string) {
	print(term.white("[${get_log_time()}] "))
	println(term.blue(s))
}

pub fn warn(s string) {
	print(term.white("[${get_log_time()}] "))
	println(term.yellow(s))
}

pub fn failed(s string) {
	print(term.white("[${get_log_time()}] "))
	println(term.red(s))
	
}

fn get_log_time() string {
	t := time.now()
	time_micro := int(t.nanosecond / 1_000)
	return t.hhmmss() + "." + "${time_micro:06}"
}


