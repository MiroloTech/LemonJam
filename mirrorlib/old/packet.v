module mirrorlib

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
	d << packet.data
	return d
}

// Debug function to display the action and data as ascii string
pub fn (packet Packet) text_str() string {
	return "[${packet.action}]" + packet.data.bytestr()
}

