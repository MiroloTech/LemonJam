module tools

import gg
import sokol.sapp

import uilib { UI, NoteUI }
import std.geom2 { Vec2, Rect2 }
import std { Color }

@[heap]
pub struct ToolMoveNotes {
	pub:
	icon                    string            = "tool-move"
	color                   Color             = Color.hex("#b595ff")
	
	pub mut:
	conv_note2world         ToolFnNoteToWorld = unsafe { nil }
	conv_world2note         ToolFnWorldToNote = unsafe { nil }
	
	note_uis                []&NoteUI
	grabbed_note            &NoteUI           = unsafe { nil }
	
	mpos                    Vec2
	
	starting_ids            []int
	starting_times          []f64
	offset_id               int
	offset_time             f64
	start_id                int
	start_time              f64
}

pub fn (tool ToolMoveNotes) get_cursor() sapp.MouseCursor {
	// > Change to grab cursor if over a note
	note := tool.get_note_at_pos(tool.mpos)
	if note != unsafe { nil } {
		return .resize_all
	}
	
	return .default
}
	
	
pub fn (mut tool ToolMoveNotes) on_ui_event(mut ui UI, event &gg.Event) {
	tool.mpos = ui.mpos
	
	// > Get grabbed note if found
	if event.typ == .mouse_down && event.mouse_button == .left {
		// > Deselect previously-grabbed note
		if tool.grabbed_note != unsafe { nil } && get_selected_notes(tool.note_uis).len <= 1 {
			tool.grabbed_note.is_selected = false
		}
		
		// > Find note at mouse and select
		note := tool.get_note_at_pos(ui.mpos)
		if note == unsafe { nil } { return }
		if !note.is_selected && get_selected_notes(tool.note_uis).len > 0 {
			deselect_all(mut tool.note_uis)
		}
		tool.grabbed_note = note
		tool.grabbed_note.is_selected = true
		
		// > Update starting positions for each note
		tool.starting_ids.clear()
		tool.starting_times.clear()
		for note_ui in get_selected_notes(tool.note_uis) {
			if note_ui.is_selected {
				tool.starting_ids << note_ui.note.id
				tool.starting_times << note_ui.note.from
			}
		}
		
		tool.start_time, tool.start_id = tool.conv_world2note(ui.mpos)
		
		// TODO : Add shift-select for multiple notes
	}
	
	// > Remove all starting data for every note
	if event.typ == .mouse_up && event.mouse_button == .left {
		tool.starting_ids.clear()
		tool.starting_times.clear()
	}
	
	// > Drack offset data
	if event.typ == .mouse_move && event.mouse_button == .left {
		time, id := tool.conv_world2note(ui.mpos)
		tool.offset_id = id - tool.start_id
		tool.offset_time = time - tool.start_time
		
		// > Update note positioning
		for i, mut note_ui in get_selected_notes(tool.note_uis) {
			start_id := tool.starting_ids[i] or { continue }
			start_time := tool.starting_times[i] or { continue }
			note_ui.note.id = start_id + tool.offset_id
			note_ui.note.from = start_time + tool.offset_time
		}
		
		// TODO : Add snapping & clamping
	}
}

pub fn (mut tool ToolMoveNotes) draw(mut ui UI) {
	
}

// Returns the first note, that has the given point `pos` inside of its shape
fn (tool ToolMoveNotes) get_note_at_pos(pos Vec2) &NoteUI {
	for note in tool.note_uis {
		if !note.is_colored { continue }
		if Rect2.from_size(note.from, note.size).is_point_inside(pos) {
			return note
		}
	}
	return unsafe { nil }
}

