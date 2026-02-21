module uilib

import gg
import math { round }

import std.geom2 { Vec2 }

pub struct VSplit {
	pub mut:
	from                Vec2
	size                Vec2
	splits              []f64                                // y starting position of every element in container
	dragger_range       f64            = 6.0
	min_split_size      f64            = 100.0
	drag_step           f64            = 25.0
	draw_draggers       bool           = true
	push_all            bool
	
	mut:
	dragging            int            = -1
	hovering            int            = -1
}

// Returns the y position and width of the given split
// Returns 0, 0 if the id is invalid
pub fn (vsplit VSplit) get_split(id int) (f64, f64) {
	y := vsplit.splits[id - 1] or { 0.0 } + vsplit.from.y
	y2 := vsplit.splits[id] or { vsplit.size.y } + vsplit.from.y
	return y, y2 - y
}

pub fn (vsplit VSplit) draw(mut ui UI) {
	// Draw split lines
	for split in vsplit.splits {
		ui.ctx.draw_line(
			f32(vsplit.from.x),                       f32(split + vsplit.from.y),
			f32(vsplit.from.x + vsplit.size.x + 0.5), f32(split + vsplit.from.y + 0.5),
			ui.style.color_panel.get_gx()
		)
	}
	
	// Set mouse mode
	if vsplit.hovering != -1 || vsplit.dragging > -1 {
		ui.set_cursor(.resize_ns)
	}
}

pub fn (mut vsplit VSplit) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	mut surpress := false
	
	vsplit.hovering = -1
	if mpos.x > vsplit.from.x && mpos.x <= vsplit.from.x + vsplit.size.x {
		for i in 0..vsplit.splits.len {
			split := vsplit.splits[i] or { 0.0 }
			dist := f64_abs(mpos.y - split - vsplit.from.y)
			if dist < vsplit.dragger_range {
				vsplit.hovering = i
				surpress = true
			}
		}
	}
	
	// Get selected split
	if event.typ == .mouse_down && vsplit.dragging == -1 {
		if vsplit.hovering != -1 {
			vsplit.dragging = vsplit.hovering
		} else {
			vsplit.dragging = -2
		}
	}
	
	// Drag split with mouse
	if event.typ == .mouse_move && vsplit.dragging > -1 {
		vsplit.splits[vsplit.dragging] = round((mpos.y - vsplit.from.y) / vsplit.drag_step) * vsplit.drag_step
		
		// Clamp to minimum size
		// > Forwards
		mut dist := vsplit.splits[0] or { return }
		for i in 0..vsplit.splits.len {
			if dist < vsplit.min_split_size {
				vsplit.splits[i] = vsplit.splits[i - 1] or { 0.0 } + vsplit.min_split_size
			}
			dist = vsplit.splits[i + 1] or { break } - vsplit.splits[i]
		}
		
		// > Backwards
		dist = vsplit.size.x - vsplit.splits.last()
		for ii in 0..vsplit.splits.len {
			i := vsplit.splits.len - 1 - ii
			if dist < vsplit.min_split_size {
				vsplit.splits[i] = vsplit.splits[i + 1] or { vsplit.size.x } - vsplit.min_split_size
			}
			dist = vsplit.splits[i] - vsplit.splits[i - 1] or { break }
		}
	}
	
	// Unselect split on release
	if event.typ == .mouse_up {
		vsplit.dragging = -1
	}
	
	if surpress && event.typ != .mouse_up {
		return surpress_event()
	}
}
