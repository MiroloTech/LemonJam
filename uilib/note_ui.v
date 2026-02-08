module uilib

import audio.objs { Note, Pattern }
import std { Color }
import std.geom2 { Vec2 }


@[heap]
pub struct NoteUI {
	pub mut:
	from         Vec2
	size         Vec2
	color        Color
	note         &Note
	is_selected  bool
	is_colored   bool
}



// ========== CONSTRUCTORS ==========

pub fn NoteUI.from_pattern(pattern &Pattern) []&NoteUI {
	mut note_uis := []&NoteUI{}
	for note in pattern.notes {
		color := pattern.colors[note] or { Color.hex("#ff0000") }
		note_uis << NoteUI.from_note(note, color)
	}
	return note_uis
}

pub fn NoteUI.from_note(note &Note, color Color) &NoteUI {
	return &NoteUI{
		color: color
		note: note
	}
}


// ========== DRAW ==========

pub fn (note_ui NoteUI) draw(mut ui UI, hashed bool) {
	ui.draw_rect(
		note_ui.from,
		note_ui.size,
		
		radius: ui.style.rounding
		fill_color: if hashed { note_ui.color.alpha(0.5) } else { note_ui.color }
		
		fill_type: if hashed { .striped } else { .full }
	)
	
	if note_ui.is_selected {
		note_ui.draw_outline(mut ui)
	}
}

pub fn (note_ui NoteUI) draw_outline(mut ui UI) {
	ui.draw_rect(
		note_ui.from,
		note_ui.size,
		
		radius: ui.style.rounding
		fill_color: Color.hex("#00000000")
		
		outline: 3.0
		outline_color: ui.style.color_text
	)
}

pub fn (note_ui NoteUI) draw_handles(mut ui UI, left bool, right bool) {
	inset := 3.0
	handle_size := Vec2{4.0, note_ui.size.y - inset * 2.0}
	left_pos := note_ui.from + Vec2.v(inset)
	right_pos := note_ui.from + Vec2{note_ui.size.x - handle_size.x - inset, inset}
	
	if left {
		ui.draw_rect(
			left_pos,
			handle_size,
			
			radius: ui.style.rounding - inset
			fill_color: ui.style.color_text
		)
	}
	if right {
		ui.draw_rect(
			right_pos,
			handle_size,
			
			radius: ui.style.rounding - inset
			fill_color: ui.style.color_text
		)
	}
}
