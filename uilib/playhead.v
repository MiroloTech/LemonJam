module uilib

import gg
import std.geom2 { Vec2 }

pub struct Playhead {
	pub mut:
	on_drag             ?fn (time f64)
	jump_scroll         ?fn (new_scroll_x f64)
	pos                 f64
	px_per_beat         f64
	scroll_x            f64
	
	from                Vec2
	size                Vec2
	hovering            bool
	dragging            bool
	
	pub:
	head_size           f64                           = 8.0
	
	mut:
	theoretical_pos     f64                           // Simmilar to pos, but can also be negative. Used to always place the playhead on the cursor, evan when the mouse overshoots the valid range
}

pub fn (playhead Playhead) draw(mut ui UI) {
	base_x := playhead.from.x
	header_offset := playhead.px_per_beat * playhead.pos - playhead.scroll_x
	head_pos := Vec2{base_x, playhead.from.y - playhead.head_size} + Vec2{header_offset, 0.0}
	
	
	// Draw line
	if header_offset > 0.001 {
		ui.ctx.draw_line(
			f32(head_pos.x), f32(head_pos.y + playhead.head_size),
			f32(head_pos.x), f32(playhead.from.y + playhead.size.y),
			ui.style.color_primary.get_gx()
		)
	}
	
	// Draw head
	// > Draw header pointing left
	if header_offset < 0.0 {
		ui.ctx.draw_polygon_filled(
			f32(base_x + playhead.head_size), f32(head_pos.y),
			f32(playhead.head_size), 3, f32(180.0),
			ui.style.color_primary.alpha(0.6).get_gx()
		)
	}
	
	// > Draw header pointing right
	else if header_offset > playhead.size.x {
		ui.ctx.draw_polygon_filled(
			f32(base_x + playhead.size.x - playhead.head_size), f32(head_pos.y),
			f32(playhead.head_size), 3, f32(0.0),
			ui.style.color_primary.alpha(0.6).get_gx()
		)
	}
	
	// > Draw current header
	else {
		ui.ctx.draw_polygon_filled(
			f32(head_pos.x), f32(head_pos.y),
			f32(playhead.head_size), 3, f32(90.0),
			ui.style.color_primary.get_gx()
		)
	}
	
	// Update mouse cursor
	if playhead.hovering {
		ui.cursor = .pointing_hand
	}
}


pub fn (mut playhead Playhead) event(event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	base_x := playhead.from.x
	head_offset := playhead.px_per_beat * playhead.pos - playhead.scroll_x
	head_pos := Vec2{base_x, playhead.from.y - playhead.head_size} + Vec2{head_offset, 0.0}
	
	left_playhead := Vec2{base_x + playhead.head_size, playhead.from.y - playhead.head_size}
	right_playhead := Vec2{playhead.from.x + playhead.size.x - playhead.head_size, playhead.from.y - playhead.head_size}
	
	hovering_left_playhead := mpos.distance_to(left_playhead) <= playhead.head_size && head_offset < 0.0
	hovering_right_playhead := mpos.distance_to(right_playhead) <= playhead.head_size && head_offset > playhead.size.x
	
	hovering_playhead := mpos.distance_to(head_pos) <= playhead.head_size && head_offset >= 0.0
	
	playhead.hovering = hovering_playhead || hovering_left_playhead || hovering_right_playhead
	
	// > Release playhead
	if event.typ == .mouse_up {
		playhead.dragging = false
	}
	if !playhead.dragging {
		playhead.theoretical_pos = playhead.pos
	}
	
	// > Move playhead
	if playhead.dragging {
		playhead.theoretical_pos += f64(event.mouse_dx) / playhead.px_per_beat
		playhead.pos = f64_max(0.0, playhead.theoretical_pos)
		// TODO : Snap to beats
		// if playhead.pos < 0.0 { playhead.pos = 0.0 }
		
		// >> Seeking
		if event.typ == .mouse_move && playhead.on_drag != none {
			playhead.on_drag(playhead.pos)
		}
		
		return uilib.surpress_event()
	}
	
	if !playhead.hovering { return }
	
	// Move / Jump to header
	if event.typ == .mouse_down && ((head_offset < 0.0 && hovering_left_playhead) || (head_offset > playhead.size.x && hovering_right_playhead)) {
		// > Jump to playhead
		if event.typ == .mouse_down && hovering_left_playhead {
			if playhead.jump_scroll != none {
				playhead.scroll_x = playhead.px_per_beat * playhead.pos - playhead.px_per_beat * 4.0
				if playhead.scroll_x < 0.0 {
					playhead.scroll_x = 0.0
				}
				playhead.jump_scroll(playhead.scroll_x)
			}
			return uilib.surpress_event()
		}
	}
	else {
		// > Grab playhead
		if event.typ == .mouse_down {
			playhead.dragging = true
			return uilib.surpress_event()
		}
	}
}
