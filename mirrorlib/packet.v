module mirrorlib

import encoding.binary

// Note: for complex structs getting sent over packets, use ```encoding.binary```'s ```encode_binary``` and ```decode_binary``` function

pub struct Packet {
	pub mut:
	action         u32
	data           []u8
}

pub fn (packet Packet) to_byte_arr() []u8 {
	len := sizeof(packet.action) + u32(packet.data.len) + u32(4)
	act := packet.action
	mut d := [
		u8((len >> 24) & u32(0xFF)), u8((len >> 16) & u32(0xFF)), u8((len >> 8) & u32(0xFF)), u8(len & u32(0xFF)), // packet length
		u8((act >> 24) & u32(0xFF)), u8((act >> 16) & u32(0xFF)), u8((act >> 8) & u32(0xFF)), u8(act & u32(0xFF)) // packet action
	]
	d << packet.data // packet data
	return d
}

// Debug function to display the action and data as ascii string
pub fn (packet Packet) text_str() string {
	return "[${packet.action}]" + packet.data.bytestr()
}

@[inline]
pub fn Packet.empty(action u32) Packet {
	return Packet{action, []u8{}}
}


pub fn Packet.from_any[T](action u32, any T) !Packet {
	$if T is voidptr {
		return Packet{
			action: action
			data: to_bytes(*any)!
		}
	}
	return Packet{
		action: action
		data: to_bytes(any)!
	}
}


// ========== UTILLITY ==========

// Little Endian type converter for types and structs. Used int ```Packet.from_any```
fn to_bytes[T](v T) ![]u8 {
	return binary.encode_binary(v)!
}

