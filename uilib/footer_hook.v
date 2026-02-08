module uilib

import sokol.sapp

pub struct FooterHook {
	pub:
	event_typ    sapp.EventType    = .mouse_down
	msg          string
}