module uilib

import gg

import std.geom2 { Vec2, Rect2 }

pub enum Direction {
	horizontal
	vertical
}

pub struct ScrollBar {
	pub mut:
	from           Vec2
	size           Vec2
	direction      Direction          = .vertical
	scroll_area    ?Rect2
	
	offset         f64                = 0.0          // Scroll offset
	range          f64                = 50.0         // Size of visible window
	max_value      f64                = 100.0        // Size of total elements in window
	step           f64                = 10.0
	
	on_drag        ?fn (v f64)
	
	mut:
	dragging       bool
}

pub fn (scroll_bar ScrollBar) draw(mut ui UI) {
	cap_radius := f64_min(scroll_bar.size.x, scroll_bar.size.y) * 0.5
	
	// Draw BG
	ui.ctx.draw_rounded_rect_filled(
		f32(scroll_bar.from.x), f32(scroll_bar.from.y),
		f32(scroll_bar.size.x), f32(scroll_bar.size.y),
		f32(cap_radius),
		ui.style.color_grey.get_gx()
	)
	
	// Draw Bar
	if scroll_bar.direction == .vertical {
		yfrom := scroll_bar.from.y + (scroll_bar.offset / scroll_bar.max_value) * scroll_bar.size.y
		ysize := f64_min(scroll_bar.range / scroll_bar.max_value, 1.0) * scroll_bar.size.y
		ui.ctx.draw_rounded_rect_filled(
			f32(scroll_bar.from.x), f32(yfrom),
			f32(scroll_bar.size.x), f32(ysize),
			f32(cap_radius),
			ui.style.color_text.alpha(0.5).get_gx()
		)
	} else {
		xfrom := scroll_bar.from.x + (scroll_bar.offset / scroll_bar.max_value) * scroll_bar.size.x
		xsize := f64_min((scroll_bar.range / scroll_bar.max_value) * scroll_bar.size.x, scroll_bar.size.x)
		ui.ctx.draw_rounded_rect_filled(
			f32(xfrom), f32(scroll_bar.from.y),
			f32(xsize), f32(scroll_bar.size.y),
			f32(cap_radius),
			ui.style.color_text.alpha(0.5).get_gx()
		)
	}
	
	
}

pub fn (mut scroll_bar ScrollBar) event(mut ui UI, event &gg.Event) ! {
	if scroll_bar.scroll_area != none {
		if !scroll_bar.scroll_area.is_point_inside(ui.mpos) {
			return
		}
	}
	if event.typ == .mouse_scroll {
		scroll_bar.offset += scroll_bar.step * -event.scroll_y
		scroll_bar.clamp()
	}
}


pub fn (mut scroll_bar ScrollBar) clamp() {
	if scroll_bar.offset + scroll_bar.range > scroll_bar.max_value {
		scroll_bar.offset = scroll_bar.max_value - scroll_bar.range
	}
	if scroll_bar.offset < 0.0 {
		scroll_bar.offset = 0.0
	}
}

pub fn (scroll_bar ScrollBar) is_in_range(v f64, size f64) bool {
	if scroll_bar.direction == .vertical {
		return v + size > scroll_bar.from.y && v < scroll_bar.from.y + scroll_bar.size.y
	}
	else {
		return v + size > scroll_bar.from.x && v < scroll_bar.from.x + scroll_bar.size.x
	}
}
