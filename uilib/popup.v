module uilib

import gg

import std.geom2 { Vec2 }

pub interface Popup {
	mut:
	from     Vec2
	size     Vec2
	
	draw(mut ui UI)
	event(mut ui UI, event &gg.Event) !
}

