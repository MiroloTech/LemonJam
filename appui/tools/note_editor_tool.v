module tools

import uilib { UI, NoteUI }
import std.geom2 { Vec2, Rect2 }

// Returns the first note, that has the given point `pos` inside of its shape
fn get_note_at_pos(pos Vec2, note_uis []&NoteUI) &NoteUI {
	for note in note_uis {
		if !note.is_colored { continue }
		if Rect2.from_size(note.from, note.size).is_point_inside(pos) {
			return note
		}
	}
	return unsafe { nil }
}

// Returns every selected note
fn get_selected_notes(note_uis []&NoteUI) []&NoteUI {
	mut notes := []&NoteUI{}
	for note in note_uis {
		if note.is_selected {
			notes << note
		}
	}
	return notes
}

// Deselects every note in the array
fn deselect_all(mut note_uis []&NoteUI) {
	for mut note in note_uis {
		note.is_selected = false
	}
}
