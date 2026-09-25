module note_editor_tools

import gg

import uilib { UI, NoteUI, RectConfig }
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

pub fn (mut tool ToolPlaceNotes) event(event &gg.Event) {
	tool.preview_time, tool.preview_id = tool.ctx.world_to_grid(tool.ctx.get_mpos())
	if event.typ == .mouse_down && event.mouse_button == .left {
		if tool.dragging == unsafe { nil } {
			// Make new note instance
			note_ui := tool.ctx.create_note_simple(tool.preview_time, 0.0, tool.preview_id, tool.ctx.active_color)
			tool.dragging = note_ui
		}
	}
	if event.typ == .mouse_move && event.mouse_button == .left {
		if tool.dragging != unsafe { nil } {
			// Drag note's length to mouse cursor
			tool.dragging.note.len = tool.preview_time - tool.dragging.note.from
			tool.ctx.force_update_note(tool.dragging)
		}
	}
	if event.typ == .mouse_up {
		if tool.dragging != unsafe { nil } {
			// Delete note, if it's len is <= 0
			if tool.dragging.note.len <= 0.0 {
				tool.ctx.delete_note(tool.dragging)
				// tool.project.delete_note(mut tool.pattern, tool.dragging.note)
			} else {
				// TODO : Unlock note here
			}
			
			tool.dragging = unsafe { nil }
		}
	}
}

pub fn (mut tool ToolPlaceNotes) draw() {
	if tool.dragging == unsafe { nil } {
		preview_pos1 := tool.ctx.grid_to_world(tool.preview_time, tool.preview_id) - Vec2{tool.preview_width * 0.5, 0.0}
		preview_pos2 := tool.ctx.grid_to_world(tool.preview_time, tool.preview_id - 1) + Vec2{tool.preview_width * 0.5, 0.0}
		
		tool.ctx.draw_rect(
			preview_pos1,
			Vec2{preview_pos2.x - preview_pos1.x, preview_pos2.y - preview_pos1.y},
			RectConfig{
				radius: tool.ctx.get_style().rounding
				fill_color: tool.ctx.get_style().color_text.alpha(0.2)
			}
		)
	} else {
		pos1 := tool.ctx.grid_to_world(tool.dragging.note.from, tool.dragging.note.id)
		pos2 := tool.ctx.grid_to_world(tool.dragging.note.from + tool.dragging.note.len, tool.dragging.note.id - 1)
		
		tool.dragging.from = pos1
		tool.dragging.size = pos2 - pos1
	}
	
}
