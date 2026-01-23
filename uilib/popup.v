module uilib

import gg

import std.geom2 { Vec2 }

pub interface Popup {
	draw(mut ui UI)
	
	mut:
	from     Vec2
	size     Vec2
	
	event(mut ui UI, event &gg.Event) !
}

