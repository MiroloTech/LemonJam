module note_editor_tools

import gg
// import sokol.sapp

import audio.objs { Note }
import uilib { UI, NoteUI }
import std.geom2 { Vec2 }
import std { Color }

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
			mut note := &Note{
				nid: unsafe { nil }
				
				from: tool.preview_time
				len: 0.0
				
				id: tool.preview_id
			}
			
			mut note_ui := &NoteUI{
				color: tool.current_color
				note: note
				is_colored: true
			}
			
			// > Get Reference to current pattern
			// TODO : This (use create_element in EditorTool)
			// tool.element_manager.create_element(new_note_ui)
			tool.dragging = note_ui
			tool.create_note(note_ui)
		}
	}
	if event.typ == .mouse_move && event.mouse_button == .left {
		if tool.dragging != unsafe { nil } {
			// Drag note's length to mouse cursor
			tool.dragging.note.len = tool.preview_time - tool.dragging.note.from
		}
	}
	if event.typ == .mouse_up {
		if tool.dragging != unsafe { nil } {
			// Delete note, if it's len is <= 0
			if tool.dragging.note.len <= 0.0 {
				tool.delete_note(tool.dragging)
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

