module appui

import gg
import math { floor, ceil, mod }
import log

import audio.objs { Note, Pattern }
import std { Color }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, ActionList }

pub struct NoteEditor {
	pub mut:
	from                         Vec2
	size                         Vec2
	
	scroll_x                     f64
	scroll_y                     f64
	pixels_per_beat              f64              = 60.0
	header_height                f64              = 60.0
	
	shown_notes                  int              = 12 * 6 + 1
	
	colors                       []Color          = [
		Color.hex("#ff8383"), Color.hex("#f17633"),
		Color.hex("#3a994c"), Color.hex("#56a2e8"),
		Color.hex("#b594ff"), Color.hex("#b8bdc2"),
		Color.hex("#aa8d84")
	]
	selected_color               int
	hovering_color               int              = -1
	
	notes                        []&Note          = []
	selected_notes               []&Note
	hovering_note                &Note            = unsafe { nil }
	left_handles                 []&Note
	right_handles                []&Note
	
	playhead_pos                 f64
	hovering_playhead            bool
	dragging_playhead            bool
	
	pub:
	note_height_white            f64              = 30.0
	note_height_black            f64              = 18.0
	note_spacing                 f64              = 1.0
	piano_width                  f64              = 180.0
	
	note_ratio_border            f64              = 0.35
	note_ratio_black             f64              = 0.35
	note_ratio_white             f64              = 0.3
	
	note_inside_drag_dist        f64              = 4.0
	note_outside_drag_dist       f64              = 12.0
	
	mut:
	panning                      bool
	pattern                      &Pattern         = unsafe { nil }
	pattern_selector             ?ActionList
	dragging_note_handles        bool
}

const note_tags := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

pub fn (editor NoteEditor) draw(mut ui UI) {
	ui.push_scissor(a: editor.from, b: editor.from + editor.size)
	
	ui.push_scissor(a: editor.from + Vec2{0.0, editor.header_height}, b: editor.from + editor.size - Vec2{0.0, editor.header_height})
	editor.draw_piano(mut ui, editor.from, editor.size)
	editor.draw_notes(mut ui)
	editor.draw_bar_lines(mut ui)
	ui.pop_scissor()
	
	editor.draw_color_selection(mut ui)
	editor.draw_tools(mut ui)
	editor.draw_playhead(mut ui)
	
	
	// Update mouse
	if editor.panning {
		ui.cursor = .resize_all
	} else if editor.hovering_color != -1 {
		ui.cursor = .pointing_hand
	} else if editor.hovering_playhead {
		ui.cursor = .pointing_hand
	} else if editor.left_handles.len > 0 || editor.right_handles.len > 0 {
		ui.cursor = .resize_ew
	} else if editor.hovering_note != unsafe { nil } {
		ui.cursor = .pointing_hand
	}
	
	ui.pop_scissor()
}

pub fn (mut editor NoteEditor) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	is_inside_window := Rect2.from_size(editor.from, editor.size).is_point_inside(mpos)
	
	/*
	// Generalized release events
	if event.typ == .mouse_up {
		editor.dragging_playhead = false
	}
	*/
	
	// Control headbar events
	editor.control_playhead(mut ui, event)!
	
	
	// Select Color
	editor.hovering_color = -1
	for i, _ in editor.colors {
		size := Vec2{20, 20}
		pos := editor.from + Vec2{editor.size.x, editor.header_height} - Vec2{size.x * 0.5, size.y * 0.5} - Vec2{20, -20} + Vec2{0.0, (size.y + ui.style.list_gap * 2.0) * f64(i)}
		if pos.x <= mpos.x && mpos.x < pos.x + size.x  &&  pos.y <= mpos.y && mpos.y < pos.y + size.y {
			editor.hovering_color = i
		}
	}
	
	if event.typ == .mouse_down && editor.hovering_color != -1 {
		editor.selected_color = editor.hovering_color
		return uilib.surpress_event()
	}
	
	
	// Control note-specific events
	editor.control_notes(mut ui, event)!
	
	
	// Move piano preview around
	if is_inside_window && event.typ == .mouse_scroll {
		if event.modifiers == 0b1 || editor.scroll_x > 0 {
			editor.scroll_x -= event.scroll_y * ui.style.scroll_speed
		} else {
			editor.scroll_y -= event.scroll_y * ui.style.scroll_speed
		}
	}
	
	// > Pan preview
	if event.typ == .mouse_move && editor.panning {
		editor.scroll_x -= event.mouse_dx * ui.style.pan_speed
		editor.scroll_y -= event.mouse_dy * ui.style.pan_speed
	}
	
	if event.typ == .mouse_down && event.mouse_button == .middle && is_inside_window {
		editor.panning = true
		return uilib.surpress_event()
	} else if event.typ == .mouse_up && event.mouse_button == .middle {
		editor.panning = false
		return uilib.surpress_event()
	}
		
	// > Clamp scrolling
	if editor.scroll_x < 0.0 { editor.scroll_x = 0.0 }
	if editor.scroll_y < 0.0 { editor.scroll_y = 0.0 }
	if editor.scroll_y + (editor.size.y - editor.header_height) > editor.total_piano_height() { editor.scroll_y = editor.total_piano_height() - (editor.size.y - editor.header_height) }
	
	if editor.panning || (is_inside_window && event.typ == .mouse_scroll) {
		return uilib.surpress_event()
	}
}

pub fn (editor NoteEditor) draw_piano(mut ui UI, from Vec2, size Vec2) {
	// Draw piano
	keys := editor.get_piano_keys(from, size)
	
	// > Draw white
	for n, rect in keys {
		if [0, 2, 4, 5, 7, 9, 11].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_note_white.get_gx()
			)
			ui.ctx.draw_text(
				int(rect.b.x - ui.style.padding * 2.0), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
				note_tags[n % 12] or { "--" },
				color: ui.style.color_grey.brighten(0.55).get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				family: ui.style.font_mono
			)
		}
		
		// >> Draw note tag for C note
		if n % 12 == 0 {
			octave := int(floor(f64(n) / 12.0))
			ui.ctx.draw_text(
				int(rect.b.x - ui.style.padding), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
				"C${octave}",
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				family: ui.style.font_mono
			)
		}
	}
	
	// > Draw black
	for n, rect in keys {
		if [1, 3, 6, 8, 10].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_note_black.get_gx()
			)
			ui.ctx.draw_text(
				int(rect.b.x - ui.style.padding), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
				note_tags[n % 12] or { "--" },
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				family: ui.style.font_mono
			)
		}
	}
	
	
	// Draw piano rails
	for n, rect in editor.get_piano_rails(from, size) {
		// > Black
		if [1, 3, 6, 8, 10].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_contrast.alpha(0.08).get_gx()
			)
		}
		
		// > White
		else {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_contrast.alpha(0.2).get_gx()
			)
		}
	}
}


pub fn (editor NoteEditor) draw_notes(mut ui UI) {
	ui.push_scissor(a: editor.from + Vec2{editor.piano_width, editor.header_height}, b: editor.from + editor.size - Vec2{editor.piano_width, editor.header_height})
	rails := editor.get_piano_rails(editor.from, editor.size)
	
	for note in editor.pattern.notes {
		color := editor.pattern.colors[note] or { Color.hex("#ffffff") }
		rail_id := int(note.id)
		rail := rails[rail_id] or {
			log.warn("Tried to draw note out of range : ${note}")
			continue
		}
		
		// TODO : Draw curved notes properly ( maybe with a pretty little shadow, when two notes cross )
		
		fromx := editor.from.x + editor.piano_width + note.from * editor.pixels_per_beat - editor.scroll_x
		sizex := note.len * editor.pixels_per_beat
		
		is_color_selected := editor.colors[editor.selected_color] == color
		if is_color_selected {
			if editor.selected_notes.contains(note) {
				ui.draw_rect(
					Vec2{fromx, rail.a.y},
					Vec2{sizex, rail.size().y},
					
					radius: ui.style.rounding
					fill_color: color
					
					outline_color: ui.style.color_text
					outline: 4.0
				)
			} else {
				ui.draw_rect(
					Vec2{fromx, rail.a.y},
					Vec2{sizex, rail.size().y},
					
					radius: ui.style.rounding
					fill_color: color
				)
			}
						
			// > Draw handle
			handle_inset := 3.0
			if note in editor.left_handles {
				ui.draw_rect(
					Vec2{fromx + handle_inset, rail.a.y + handle_inset},
					Vec2{4.0, rail.size().y - handle_inset * 2.0},
					
					radius: ui.style.rounding - handle_inset
					fill_color: ui.style.color_text
				)
			}
			if note in editor.right_handles {
				ui.draw_rect(
					Vec2{fromx + sizex - handle_inset - 4.0, rail.a.y + handle_inset},
					Vec2{4.0, rail.size().y - handle_inset * 2.0},
					
					radius: ui.style.rounding - handle_inset
					fill_color: ui.style.color_text
				)
			}
		} else {
			// > Draw un-focused notes
			inset := 2.0
			ui.draw_rect(
				Vec2{fromx, rail.a.y},
				Vec2{sizex, rail.size().y},
				
				radius: ui.style.rounding
				inset: inset
				fill_color: color
				fill_type: .double
				outline: inset
				outline_color: if editor.selected_notes.contains(note) { ui.style.color_text } else { color }
			)
		}
	}
	
	ui.pop_scissor()
}


pub fn (editor NoteEditor) draw_bar_lines(mut ui UI) {
	ui.push_scissor(a: editor.from + Vec2{editor.piano_width - 1, editor.header_height * 0.75}, b: editor.from + editor.size - Vec2{editor.piano_width, editor.header_height * 0.75})
	
	// Draw beat & bar lines
	lines := int(ceil(editor.size.x / editor.pixels_per_beat)) + 1
	for l in 0..lines {
		beat := int(floor(f64(l + editor.scroll_x / editor.pixels_per_beat)))
		line_pos := editor.piano_width + f64(l) * editor.pixels_per_beat - mod(editor.scroll_x, editor.pixels_per_beat)
		over_header_extension := if beat % 4 == 0 { 0.25 } else { 0.0 }
		ui.ctx.draw_line(
			f32(editor.from.x + line_pos), f32(editor.from.y + editor.header_height * (1.0 - over_header_extension)),
			f32(editor.from.x + line_pos), f32(editor.from.y + editor.size.y),
			if beat % 4 == 0 { ui.style.color_grey.alpha(0.8).get_gx() } else { ui.style.color_grey.alpha(0.2).get_gx() }
		)
		
		// Draw bar counter
		if beat % 4 == 0 {
			ui.ctx.draw_text(
				int(editor.from.x + line_pos + 2.0), int(editor.from.y + editor.header_height * (1.0 - over_header_extension)),
				"${beat / 4}",
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .left
				vertical_align: .top
				family: ui.style.font_mono
			)
		}
	}
	
	ui.pop_scissor()
}


pub fn (editor NoteEditor) draw_playhead(mut ui UI) {
	head_size := 8.0
	base_x := editor.from.x + editor.piano_width
	header_offset := editor.pixels_per_beat * editor.playhead_pos - editor.scroll_x
	head_pos := Vec2{base_x, editor.from.y + editor.header_height - head_size} + Vec2{header_offset, 0.0}
	
	
	// Draw line
	if header_offset > 0.001 {
		ui.ctx.draw_line(
			f32(head_pos.x), f32(head_pos.y + head_size),
			f32(head_pos.x), f32(editor.from.y + editor.size.y),
			ui.style.color_primary.get_gx()
		)
	}
	
	// Draw head
	// > Draw header pointing left
	if header_offset < 0.0 {
		ui.ctx.draw_polygon_filled(
			f32(base_x + head_size), f32(head_pos.y),
			f32(head_size), 3, f32(180.0),
			ui.style.color_primary.alpha(0.6).get_gx()
		)
	}
	
	// > Draw header pointing right
	else if header_offset > editor.size.x - editor.piano_width {
		ui.ctx.draw_polygon_filled(
			f32(base_x + editor.size.x - editor.piano_width - head_size), f32(head_pos.y),
			f32(head_size), 3, f32(0.0),
			ui.style.color_primary.alpha(0.6).get_gx()
		)
	}
	
	// > Draw current header
	else {
		ui.ctx.draw_polygon_filled(
			f32(head_pos.x), f32(head_pos.y),
			f32(head_size), 3, f32(90.0),
			ui.style.color_primary.get_gx()
		)
	}
}



pub fn (editor NoteEditor) draw_color_selection(mut ui UI) {
	for i, color in editor.colors {
		size := Vec2{20, 20}
		pos := editor.from + Vec2{editor.size.x, editor.header_height} - Vec2{size.x * 0.5, size.y * 0.5} - Vec2{20, -20} + Vec2{0.0, (size.y + ui.style.list_gap * 2.0) * f64(i)}
		ui.ctx.draw_rounded_rect_filled(
			f32(pos.x), f32(pos.y),
			f32(size.x), f32(size.y),
			f32(ui.style.rounding),
			color.get_gx()
		)
		
		if i == editor.selected_color {
			inset := 2.0
			ui.ctx.draw_rounded_rect_filled(
				f32(pos.x + inset), f32(pos.y + inset),
				f32(size.x - inset * 2.0), f32(size.y - inset * 2.0),
				f32(ui.style.rounding - inset),
				ui.style.color_panel.get_gx()
			)
			ui.draw_rounded_double_striped_rect(
				pos + Vec2.v(inset),
				size - Vec2.v(inset * 2.0),
				ui.style.rounding - inset,
				color.darken(0.2)
			)
		}
	}
}



// Presents all headbar data except for the bar line counter ( handelerd in draw_bar_lines )
pub fn (editor NoteEditor) draw_tools(mut ui UI) {
	// Draw vertical split line
	ui.ctx.draw_line(
		f32(editor.from.x),                 f32(editor.from.y + editor.header_height * 0.5),
		f32(editor.from.x + editor.size.x), f32(editor.from.y + editor.header_height * 0.5),
		ui.style.color_panel.get_gx()
	)
	
	// Draw pattern selector
	pattern_name := if editor.pattern == unsafe { nil } { "---" } else { editor.pattern.name }
	icon_size := editor.header_height * 0.5 - ui.style.padding * 2.0
	ui.ctx.draw_line(
		f32(editor.from.x + editor.piano_width), f32(editor.from.y + editor.header_height * 0.5),
		f32(editor.from.x + editor.piano_width), f32(editor.from.y + editor.header_height),
		ui.style.color_panel.get_gx()
	)
	
	ui.ctx.draw_text(
		int(editor.from.x + ui.style.padding * 2.0), int(editor.from.y + editor.header_height * 0.75),
		pattern_name,
		color: ui.style.color_text.alpha(0.65).get_gx()
		size: int(icon_size)
		align: .left
		vertical_align: .middle
		family: ui.style.font_regular
	)
	/*
	ui.draw_icon(
		"point-down",
		editor.from + Vec2{editor.piano_width - ui.style.padding - icon_size, editor.header_height * 0.5 + ui.style.padding},
		Vec2.v(icon_size),
		ui.style.color_text.alpha(0.65)
	)
	*/
}





// Returns an array of all keys for every note in the given range
fn (editor NoteEditor) get_piano_keys(from Vec2, size Vec2) []Rect2 {
	mut y := -editor.scroll_y + editor.header_height
	mut keys := []Rect2{}
	
	for i in 0..editor.shown_notes {
		n := editor.shown_notes - i - 1
		// > Black keys
		if [1, 3, 6, 8, 10].contains(n % 12) {
			keys << Rect2.from_size(
				from + Vec2{0.0, y - editor.note_height_black * 0.5},
				Vec2{editor.piano_width * 0.7, editor.note_height_black}
			)
		}
		// > White keys
		else {
			keys << Rect2.from_size(
				from + Vec2{0.0, y},
				Vec2{editor.piano_width, editor.note_height_white}
			)
			y += editor.note_height_white + editor.note_spacing
		}
	}
	
	return keys.reverse()
}

fn (editor NoteEditor) get_piano_rails(from Vec2, size Vec2) []Rect2 {
	mut y := -editor.scroll_y + editor.header_height
	mut rails := []Rect2{}
	
	octave_height := editor.note_height_white * 7.0
	
	for i in 0..editor.shown_notes {
		n := editor.shown_notes - i - 1
		is_white := [0, 2, 4, 5, 7, 9, 11].contains(n % 12)
		is_border := [0, 4, 5, 11].contains(n % 12)
		h := if i == 0 {
			editor.note_height_white + editor.note_spacing
		} else if is_border {
			editor.note_ratio_border / 4.0 * octave_height + editor.note_spacing
		} else {
			if is_white {
				editor.note_ratio_white / 3.0 * octave_height + editor.note_spacing
			} else {
				editor.note_ratio_black / 5.0 * octave_height
			}
		}
		
		rails << Rect2.from_size(from + Vec2{editor.piano_width, y}, Vec2{size.x - editor.piano_width, h})
		
		y += h
	}
	
	return rails.reverse()
}


fn (editor NoteEditor) total_piano_height() f64 {
	octaves := int(floor(f64(editor.shown_notes) / 12.0))
	remaining := editor.shown_notes % 12
	white_notes := octaves * 7 + [0, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7][remaining] or { 0 }
	return f64(white_notes) * (editor.note_height_white + editor.note_spacing)
}



// ========== EVENT CONTROLS ==========

pub fn (mut editor NoteEditor) control_notes(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	editing_rect := Rect2{a: editor.from + Vec2{editor.piano_width, editor.header_height}, b: editor.from + editor.size}
	editor.hovering_note = unsafe { nil }
	
	if !editing_rect.is_point_inside(mpos) { return }
	
	rails := editor.get_piano_rails(editor.from, editor.size)
	
	// > Reset handles
	if !editor.dragging_note_handles {
		editor.right_handles = []
		editor.left_handles = []
	}
	
	for note in editor.pattern.notes {
		color := editor.pattern.colors[note] or { Color.hex("#ffffff") }
		rail_id := int(note.id)
		rail := rails[rail_id] or {
			log.warn("Tried to draw note out of range : ${note}")
			continue
		}
		
		fromx := editor.from.x + editor.piano_width + note.from * editor.pixels_per_beat - editor.scroll_x
		sizex := note.len * editor.pixels_per_beat
		
		is_color_selected := editor.colors[editor.selected_color] == color
		note_rect := Rect2.from_size(Vec2{fromx, rail.a.y}, Vec2{sizex, rail.size().y})
		if is_color_selected && note_rect.is_point_inside(mpos) && editor.hovering_note == unsafe { nil } {
			editor.hovering_note = note
		}
		
		// Set handles
		is_mouse_in_rail := rail.a.y <= mpos.y && mpos.y < rail.b.y
		if is_mouse_in_rail && is_color_selected && !editor.dragging_note_handles {
			// > Calculate the distance from the mouse to the edges of the note to determine the handles
			dist_left := fromx - mpos.x
			dist_right := (fromx + sizex) - mpos.x
			
			// > Determine which handle to aply to each side
			if f64_abs(dist_right) <= editor.note_inside_drag_dist || (dist_right < editor.note_outside_drag_dist && dist_right > 0.0) {
				editor.right_handles << note
			}
			
			if f64_abs(dist_left) <= editor.note_inside_drag_dist || (-dist_left < editor.note_outside_drag_dist && -dist_left > 0.0) {
				editor.left_handles << note
			}
		}
	}
	
	if event.typ == .mouse_down && event.mouse_button == .left {
		if editor.left_handles.len > 0 || editor.right_handles.len > 0 {
			editor.dragging_note_handles = true
		} else if editor.hovering_note == unsafe { nil } {
			editor.selected_notes = []
		} else if event.modifiers & 0b1 == 0b1 {
			editor.selected_notes << editor.hovering_note
		} else {
			editor.selected_notes = [editor.hovering_note]
		}
		return uilib.surpress_event()
	}
	
	if event.typ == .mouse_move && editor.dragging_note_handles {
		step := f64(event.mouse_dx) / editor.pixels_per_beat
		for mut right in editor.right_handles {
			right.len += step
		}
		for mut left in editor.left_handles {
			left.from += step
			left.len -= step
		}
	}
	
	if event.typ == .mouse_up {
		editor.dragging_note_handles = false
		// ... left and right handles recalculated on release event
	}
}


pub fn (mut editor NoteEditor) control_playhead(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	head_size := 8.0
	base_x := editor.from.x + editor.piano_width
	head_offset := editor.pixels_per_beat * editor.playhead_pos - editor.scroll_x
	head_pos := Vec2{base_x, editor.from.y + editor.header_height - head_size} + Vec2{head_offset, 0.0}
	
	left_playhead := Vec2{base_x + head_size, editor.from.y + editor.header_height - head_size}
	right_playhead := Vec2{editor.from.x + editor.size.x - head_size, editor.from.y + editor.header_height - head_size}
	
	hovering_left_playhead := mpos.distance_to(left_playhead) <= head_size && head_offset < 0.0
	hovering_right_playhead := mpos.distance_to(right_playhead) <= head_size && head_offset > editor.size.x - editor.piano_width
	
	hovering_playhead := mpos.distance_to(head_pos) <= head_size && head_offset >= 0.0
	
	editor.hovering_playhead = hovering_playhead || hovering_left_playhead || hovering_right_playhead
	
	// > Release playhead
	if event.typ == .mouse_up {
		editor.dragging_playhead = false
	}
	
	// > Move playhead
	if editor.dragging_playhead {
		editor.playhead_pos += f64(event.mouse_dx) / editor.pixels_per_beat
		if editor.playhead_pos < 0.0 { editor.playhead_pos = 0.0 }
		return uilib.surpress_event()
	}
	
	if !editor.hovering_playhead { return }
	
	// Move / Jump to header
	if head_offset < 0.0 {
		// > Jump to playhead
		if event.typ == .mouse_down && hovering_left_playhead {
			editor.scroll_x = editor.pixels_per_beat * editor.playhead_pos - editor.pixels_per_beat * 4.0
			if editor.scroll_x < 0.0 {
				editor.scroll_x = 0.0
			}
			return uilib.surpress_event()
		}
	}
	
	else if head_offset > editor.size.x - editor.piano_width {
		// > Jump to playhead
		if event.typ == .mouse_down && hovering_right_playhead {
			editor.scroll_x = editor.pixels_per_beat * editor.playhead_pos - editor.pixels_per_beat * 4.0
			if editor.scroll_x < 0.0 {
				editor.scroll_x = 0.0
			}
			return uilib.surpress_event()
		}
	}
	
	else {
		// > Grab playhead
		if event.typ == .mouse_down {
			editor.dragging_playhead = true
			return uilib.surpress_event()
		}
	}
}


pub fn (mut editor NoteEditor) open_pattern(pattern &Pattern) {
	editor.pattern = pattern
	editor.notes = pattern.notes
}


/*
Next simplified TODO:
- Implement new event system into more components
- Note dragging & removing
- Simple saving to test loading
- Instrument selection & note highlighting in note editor
- Split note editor into multiple files to clean up code
*/
