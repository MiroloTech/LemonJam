module uilib

import gg
import math { round }

import std.geom2 { Vec2 }

pub struct HSplit {
	pub mut:
	from                Vec2
	size                Vec2
	splits              []f64                                // x starting position of every element in container
	dragger_range       f64            = 6.0
	min_split_size      f64            = 100.0
	drag_step           f64            = 25.0
	draw_draggers       bool           = true
	push_all            bool
	
	mut:
	dragging            int            = -1
	hovering            int            = -1
}

// Returns the x position and width of the given split
// Returns 0, 0 if the id is invalid
pub fn (hsplit HSplit) get_split(id int) (f64, f64) {
	x := hsplit.splits[id - 1] or { 0.0 } + hsplit.from.x
	x2 := hsplit.splits[id] or { hsplit.size.x } + hsplit.from.x
	return x, x2 - x
}

pub fn (hsplit HSplit) draw(mut ui UI) {
	// Draw split lines
	for split in hsplit.splits {
		ui.ctx.draw_line(
			f32(split + hsplit.from.x + 0.5), f32(hsplit.from.y + 0.5),
			f32(split + hsplit.from.x),       f32(hsplit.from.y + hsplit.size.y),
			ui.style.color_panel.get_gx()
		)
	}
	
	// Set mouse mode
	if hsplit.hovering != -1 || hsplit.dragging > -1 {
		ui.cursor = .resize_ew
	}
}

pub fn (mut hsplit HSplit) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	mut surpress := false
	
	hsplit.hovering = -1
	if mpos.y > hsplit.from.y && mpos.y <= hsplit.from.y + hsplit.size.y {
		for i in 0..hsplit.splits.len {
			split := hsplit.splits[i] or { 0.0 }
			dist := f64_abs(mpos.x - split)
			if dist < hsplit.dragger_range {
				hsplit.hovering = i
				surpress = true
			}
		}
	}
	
	// Get selected split
	if event.typ == .mouse_down && hsplit.dragging == -1 {
		if hsplit.hovering != -1 {
			hsplit.dragging = hsplit.hovering
		} else {
			hsplit.dragging = -2
		}
	}
	
	// Drag split with mouse
	if event.typ == .mouse_move && hsplit.dragging > -1 {
		hsplit.splits[hsplit.dragging] = round((mpos.x - hsplit.from.x) / hsplit.drag_step) * hsplit.drag_step
		
		// Clamp to minimum size
		// > Forwards
		mut dist := hsplit.splits[0] or { return }
		for i in 0..hsplit.splits.len {
			if dist < hsplit.min_split_size {
				hsplit.splits[i] = hsplit.splits[i - 1] or { 0.0 } + hsplit.min_split_size
			}
			dist = hsplit.splits[i + 1] or { break } - hsplit.splits[i]
		}
		
		// > Backwards
		dist = hsplit.size.x - hsplit.splits.last()
		for ii in 0..hsplit.splits.len {
			i := hsplit.splits.len - 1 - ii
			if dist < hsplit.min_split_size {
				hsplit.splits[i] = hsplit.splits[i + 1] or { hsplit.size.x } - hsplit.min_split_size
			}
			dist = hsplit.splits[i] - hsplit.splits[i - 1] or { break }
		}
	}
	
	// Unselect split on release
	if event.typ == .mouse_up {
		hsplit.dragging = -1
	}
	
	if surpress && event.typ != .mouse_up {
		return surpress_event()
	}
}
