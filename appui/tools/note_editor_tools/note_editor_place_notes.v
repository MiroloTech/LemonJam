module note_editor_tools

import gg

import uilib { UI, NoteUI }
import std.geom2 { Vec2 }
import std { Color, ByteStack }

@[heap]
pub struct ToolPlaceNotes {
	NoteEditorTool
	
	pub:
	icon                    string            = "tool-paint"
	color                   Color             = Color.hex("#32a783")
	
	pub mut:
	preview_width           f64               = 6.0
	preview_time            f64
	preview_id              int
	
	dragging                &NoteUI           = unsafe { nil }
}

pub fn (mut tool ToolPlaceNotes) event(mut ui UI, event &gg.Event) {
	tool.preview_time, tool.preview_id = tool.grid_world_conv.world_to_grid(ui.mpos)
	if event.typ == .mouse_down && event.mouse_button == .left {
		if tool.dragging == unsafe { nil } {
			// Make new note instance here
			mut note := tool.project.new_note_simple(tool.preview_time, 0.0, tool.preview_id, tool.current_color, mut tool.pattern, unsafe { nil })
			
			mut note_ui := &NoteUI{
				note: note
				is_colored: true
			}
			
			tool.dragging = note_ui
			
			// > Crate note in session context
			tool.create_note(note_ui)
		}
	}
	if event.typ == .mouse_move && event.mouse_button == .left {
		if tool.dragging != unsafe { nil } {
			// Drag note's length to mouse cursor
			tool.dragging.note.len = tool.preview_time - tool.dragging.note.from
			tool.project.update_note(tool.dragging.note)
		}
	}
	if event.typ == .mouse_up {
		if tool.dragging != unsafe { nil } {
			// Delete note, if it's len is <= 0
			if tool.dragging.note.len <= 0.0 {
				tool.delete_note(tool.dragging)
				tool.project.delete_note(mut tool.pattern, tool.dragging.note)
			} else {
				// TODO : Unlock note here
			}
			
			tool.dragging = unsafe { nil }
		}
	}
}

pub fn (mut tool ToolPlaceNotes) draw(mut ui UI) {
	if tool.dragging == unsafe { nil } {
		preview_pos1 := tool.grid_world_conv.grid_to_world(tool.preview_time, tool.preview_id) - Vec2{tool.preview_width * 0.5, 0.0}
		preview_pos2 := tool.grid_world_conv.grid_to_world(tool.preview_time, tool.preview_id - 1) + Vec2{tool.preview_width * 0.5, 0.0}
		
		ui.draw_rect(
			preview_pos1,
			Vec2{preview_pos2.x - preview_pos1.x, preview_pos2.y - preview_pos1.y},
			radius: ui.style.rounding
			fill_color: ui.style.color_text.alpha(0.2)
		)
	} else {
		pos1 := tool.grid_world_conv.grid_to_world(tool.dragging.note.from, tool.dragging.note.id)
		pos2 := tool.grid_world_conv.grid_to_world(tool.dragging.note.from + tool.dragging.note.len, tool.dragging.note.id - 1)
		
		tool.dragging.from = pos1
		tool.dragging.size = pos2 - pos1
	}
	
}
