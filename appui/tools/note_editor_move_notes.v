module tools

import gg

import uilib { UI, NoteUI }
// import std.geom2 { Vec2, Rect2 }
import std { Color }

@[heap]
pub struct ToolMoveNotes {
	EditorTool[NoteUI]
	
	pub:
	icon                    string            = "tool-move"
	color                   Color             = Color.hex("#b595ff")
	
	pub mut:
	grabbed_note            &NoteUI           = unsafe { nil }
	
	starting_ids            []int
	starting_times          []f64
	offset_id               int
	offset_time             f64
	start_id                int
	start_time              f64
}
	
	
pub fn (mut tool ToolMoveNotes) event(mut ui UI, event &gg.Event) {
	// > Get grabbed note if found
	if event.typ == .mouse_down && event.mouse_button == .left {
		// > Deselect previously-grabbed note
		if tool.grabbed_note != unsafe { nil } && get_selected_notes(tool.elements).len <= 1 {
			tool.grabbed_note.is_selected = false
		}
		
		// > Find note at mouse and select
		note := get_note_at_pos(ui.mpos, tool.elements)
		if note == unsafe { nil } { return }
		if !note.is_selected && get_selected_notes(tool.elements).len > 0 {
			deselect_all(mut tool.elements)
		}
		tool.grabbed_note = note
		tool.grabbed_note.is_selected = true
		
		// > Update starting positions for each note
		tool.starting_ids.clear()
		tool.starting_times.clear()
		for note_ui in get_selected_notes(tool.elements) {
			if note_ui.is_selected {
				tool.starting_ids << note_ui.note.id
				tool.starting_times << note_ui.note.from
			}
		}
		
		tool.start_time, tool.start_id = tool.grid_world_conv.world_to_grid(ui.mpos)
		
		// TODO : Add shift-select for multiple notes
	}
	
	// > Remove all starting data for every note
	if event.typ == .mouse_up && event.mouse_button == .left {
		tool.starting_ids.clear()
		tool.starting_times.clear()
	}
	
	// > Drack offset data
	if event.typ == .mouse_move && event.mouse_button == .left {
		time, id := tool.grid_world_conv.world_to_grid(ui.mpos)
		tool.offset_id = id - tool.start_id
		tool.offset_time = time - tool.start_time
		
		// > Update note positioning
		for i, mut note_ui in get_selected_notes(tool.elements) {
			start_id := tool.starting_ids[i] or { continue }
			start_time := tool.starting_times[i] or { continue }
			note_ui.note.id = start_id + tool.offset_id
			note_ui.note.from = start_time + tool.offset_time
		}
		
		// TODO : Add snapping & clamping
	}
}

pub fn (mut tool ToolMoveNotes) draw(mut ui UI) {
	// Update cursor
	hovered_note := get_note_at_pos(ui.mpos, tool.elements) // tool.get_note_at_pos(tool.mpos)
	if hovered_note != unsafe { nil } {
		ui.set_cursor(.resize_all)
	} else {
		ui.set_cursor(.default)
	}
	
}

