module uilib

import gg
import std { Color }
import std.geom2 { Vec2 }

pub fn (mut ui UI) draw_icon(icon string, from Vec2, size Vec2, color Color) {
	ui.ctx.draw_image_with_config(
		img: ui.icons[icon] or { ui.not_found_icon }
		img_rect: gg.Rect{ x: f32(from.x + 0.5), y: f32(from.y + 0.5), width: f32(size.x), height: f32(size.y) }
		color: color.get_gx()
	)
}
