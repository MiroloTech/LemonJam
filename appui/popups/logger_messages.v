module popups

import net.http { Request, Response, Method }

import std { Color }
import std.log { LogData, LogDebug, LogInfo, LogError, LogHttpRequest, LogHttpResponse, LogTcpIn, LogTcpOut }
import uilib { UI }
import mirrorlib

pub enum LogMessageFormat {
	txt
	hex
	bin
	json
	obj
}


interface LogMessageContent {
	valid_format         []LogMessageFormat
	icon                 string
	
	get_title(format LogMessageFormat) string
	get_body(format LogMessageFormat) string
	get_color(ui UI) Color
}



// === DEBUG MESSAGE ===
pub struct LogMessageDebug implements LogMessageContent {
	pub:
	data                 string                                              @[required]
	
	valid_format         []LogMessageFormat              = [.txt]
	icon                 string                          = "log-debug"
}

pub fn (msg LogMessageDebug) get_title(_ LogMessageFormat) string {
	return msg.data.replace("\t", "    ")
}

pub fn (msg LogMessageDebug) get_body(_ LogMessageFormat) string {
	return msg.data.replace("\t", "    ")
}

pub fn (msg LogMessageDebug) get_color(ui UI) Color {
	return ui.style.color_log_txt
}


// === INFO MESSAGE ===
pub struct LogMessageInfo implements LogMessageContent {
	pub:
	data                 string                                              @[required]
	
	valid_format         []LogMessageFormat              = [.txt]
	icon                 string                          = "log-info"
}

pub fn (msg LogMessageInfo) get_title(_ LogMessageFormat) string {
	return msg.data.replace("\t", "    ")
}

pub fn (msg LogMessageInfo) get_body(_ LogMessageFormat) string {
	return msg.data.replace("\t", "    ")
}

pub fn (msg LogMessageInfo) get_color(ui UI) Color {
	return ui.style.color_log_info
}


// === ERROR MESSAGE ===
pub struct LogMessageError implements LogMessageContent {
	pub:
	data                 string                                              @[required]
	
	valid_format         []LogMessageFormat              = [.txt]
	icon                 string                          = "log-error"
}

pub fn (msg LogMessageError) get_title(_ LogMessageFormat) string {
	return msg.data.all_before(" : ").replace("\t", "    ")
}

pub fn (msg LogMessageError) get_body(_ LogMessageFormat) string {
	return msg.data.replace(" : ", "\n").replace("\t", "    ")
}

pub fn (msg LogMessageError) get_color(ui UI) Color {
	return ui.style.color_log_error
}


// === HTTP MESSAGE ===
type HttpRequestResponse = Request | string | Response

pub struct LogMessageHTTP implements LogMessageContent {
	pub:
	data                 HttpRequestResponse                                 @[required] // If string is uesd instead of request, make sure to give the method like so : "get|google.com"
	
	valid_format         []LogMessageFormat              = [.txt]
	icon                 string                          = "log-http"
}

pub fn (msg LogMessageHTTP) get_title(_ LogMessageFormat) string {
	if msg.data is Request {
		return msg.data.method.str() + " | " + msg.data.url
	} else if msg.data is string {
		return msg.data.replace_once("|", " | ")
	} else if msg.data is Response {
		return msg.data.body
	}
	return ""
}

pub fn (msg LogMessageHTTP) get_body(_ LogMessageFormat) string {
	if msg.data is Request {
		return msg.data.str()
	} else if msg.data is string {
		return Request{
			url: msg.data.all_after("|")
			method: http_method_from_string(msg.data.all_before("|")) or { Method.get }
		}.str()
	} else {
		return msg.data.str()
	}
}

pub fn (msg LogMessageHTTP) get_color(ui UI) Color {
	return ui.style.color_log_http
}

fn http_method_from_string(method string) !Method {
	return match method.to_lower() {
		"get" { .get }
		"post" { .post }
		"patch" { .patch }
		"put" { .put }
		"head" { .head }
		"options" { .options }
		"delete" { .delete }
		else { error("Invalid method tag given : ${method}") }
	}
}


// === TCP IN MESSAGE ===
pub struct LogMessageTCP_IN implements LogMessageContent {
	pub:
	action               u32                                                 @[required]
	data                 []u8                                                @[required]
	
	valid_format         []LogMessageFormat              = [.hex, .bin, .txt, .obj]
	icon                 string                          = "log-tcp-in"
}

pub fn (msg LogMessageTCP_IN) get_title(format LogMessageFormat) string {
	mut s := "TCP in | " + mirrorlib.action_tags[msg.action] or { "unknown-action" } + if msg.data.len > 0 { " - " } else { '' }
	match format {
		.txt { for d in msg.data { s += d.str_escaped() } }
		.hex { for d in msg.data { s += d.hex() + " " } }
		.bin { for d in msg.data { s += "${u8_to_bin(d):08} " } }
		.obj { s += profiled_msg_data(msg.data) or { "?" } }
		else {  }
	}
	return s
}

pub fn (msg LogMessageTCP_IN) get_body(format LogMessageFormat) string {
	mut s := "Action: " + mirrorlib.action_tags[msg.action] or { "unknown-action" } + "\n\n"
	match format {
		.txt {
			for d in msg.data {
				s += d.str_escaped()
			}
		}
		.hex {
			mut chars := []u8{}
			for i, d in msg.data {
				s += d.hex() + " "
				chars << d
				if i % 8 == 7 {
					s += "  :  "
					for c in chars {
						s += if c > 31 && c < 127 { c.ascii_str() } else { "." } + " "
					}
					chars.clear()
					
					if i != msg.data.len - 1 {
						s += "\n"
					}
				}
			}
			if msg.data.len % 8 != 0 {
				s += "   ".repeat(8 - (msg.data.len % 8)) + "  :  "
				for c in chars {
					s += if c > 31 && c < 127 { c.ascii_str() } else { "." } + " "
				}
			}
		}
		.bin {
			for i, d in msg.data {
				s += "${u8_to_bin(d):08} "
				if i % 8 == 7 {
					if i != msg.data.len - 1 {
						s += "\n"
					}
				}
			}
		}
		.obj { s += profiled_msg_data(msg.data) or { "?" } }
		else {  }
	}
	return s
}

pub fn (msg LogMessageTCP_IN) get_color(ui UI) Color {
	return ui.style.color_log_tcp
}

fn u8_to_bin(v u8) u32 {
	return u32(1)      * (u32(v     ) & u32(0b1))  +  u32(10)      * (u32(v >> 1) & u32(0b1))  +  u32(100)       * (u32(v >> 2) & u32(0b1))  +  u32(1000)       * (u32(v >> 3) & u32(0b1)) + 
		   u32(10_000) * (u32(v >> 4) & u32(0b1))  +  u32(100_000) * (u32(v >> 5) & u32(0b1))  +  u32(1_000_000) * (u32(v >> 6) & u32(0b1))  +  u32(10_000_000) * (u32(v >> 7) & u32(0b1))
}

// Detects and auto-applies a specific profile based on a big profile .json file, which lists decryption instructions for different objects and detection methods to determine the obj from data []u8
// Returns decrypted object as text or formatting error
fn profiled_msg_data(data []u8) !string {
	return ""
}


// === TCP OUT MESSAGE ===
pub struct LogMessageTCP_OUT implements LogMessageContent {
	LogMessageTCP_IN
	icon                 string                          = "log-tcp-out"
}

pub fn (msg LogMessageTCP_OUT) get_title(format LogMessageFormat) string {
	mut s := "TCP out | " + mirrorlib.action_tags[msg.action] or { "unknown-action" } + if msg.data.len > 0 { " - " } else { '' }
	match format {
		.txt { for d in msg.data { s += d.str_escaped() } }
		.hex { for d in msg.data { s += d.hex() + " " } }
		.bin { for d in msg.data { s += "${u8_to_bin(d):08} " } }
		.obj { s += profiled_msg_data(msg.data) or { "?" } }
		else {  }
	}
	return s
}




pub fn LogMessage.from_log_data(entry LogData) LogMessage {
	mut content := LogMessageContent(LogMessageError{data: "???"})
	match entry {
		LogDebug          { content = LogMessageDebug{data: entry} }
		LogInfo           { content = LogMessageInfo{data: entry} }
		LogError          { content = LogMessageError{data: entry} }
		LogHttpRequest    { content = LogMessageHTTP{data: if entry is string { HttpRequestResponse(entry) } else { HttpRequestResponse(entry as http.Request) } } }
		LogHttpResponse   { content = LogMessageHTTP{data: HttpRequestResponse(entry)} }
		LogTcpIn          { content = LogMessageTCP_IN{action: entry.action, data: entry.data} }
		LogTcpOut         { content = LogMessageTCP_OUT{action: entry.action, data: entry.data} }
	}
	
	return LogMessage.new(content)
}
