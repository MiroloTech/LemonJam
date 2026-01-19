module uilib

import gg
import sokol.sapp

import std.geom2 { Vec2 }

pub struct Event {
	frame_count    u64
	typ            sapp.EventType
	
	mpos           Vec2
	mdelta         Vec2
	
	key_repeat     bool
	char_code      u32
	key_code       gg.KeyCode
	
	window_size    Vec2
}

