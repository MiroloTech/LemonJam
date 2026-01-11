module uilib

import std.geom2 { Vec2 }
import std { Color }

pub struct ColorRect {
	pub mut:
	from       Vec2
	size       Vec2
	text       string
	
	color      Color
	rounded    bool
}


pub fn (mut color_rect ColorRect) draw(mut ui UI) {
	ui.ctx.draw_rounded_rect_filled(
		f32(color_rect.from.x), f32(color_rect.from.y),
		f32(color_rect.size.x), f32(color_rect.size.y),
		f32(if color_rect.rounded { ui.style.rounding } else { 0.0 }),
		color_rect.color.get_gx()
	)
}
