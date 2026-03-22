module note_editor_tools

import gg
// import sokol.sapp

import uilib { UI, NoteUI }
// import std.geom2 { Vec2 }
import std { Color }

@[heap]
pub struct ToolDeleteNotes {
	NoteEditorTool
	
	pub:
	icon                    string            = "tool-erase"
	color                   Color             = Color.hex("#ff8383")
	
	pub mut:
	queue                   []&NoteUI
	queue_colors            []Color
	dragging                bool
}

pub fn (mut tool ToolDeleteNotes) event(mut ui UI, event &gg.Event) {
	// Begin deletion
	if event.typ == .mouse_down && event.mouse_button == .left {
		tool.dragging = true
		tool.queue.clear()
	}
	
	// Add hovered notes to queue
	if event.typ == .mouse_move && tool.dragging {
		mut hovered_note := get_note_at_pos(ui.mpos, tool.elements)
		if hovered_note != unsafe { nil } {
			if !tool.queue.contains(hovered_note) {
				tool.queue << hovered_note
				tool.queue_colors << hovered_note.color
				
				// > Highlight note to delete
				hovered_note.color = ui.style.color_grey
			}
		}
	}
	
	// Cancel deletion
	if event.typ == .key_down && event.key_code == .escape && tool.dragging {
		tool.dragging = false
		tool.cancel_deletion()
	}
	
	// Delete all notes in queue
	if event.typ == .mouse_up && event.mouse_button == .left && tool.dragging {
		tool.dragging = false
		tool.delete_all_in_queue()
	}
}

pub fn (mut tool ToolDeleteNotes) draw(mut ui UI) {
	// Update cursor
	hovered_note := get_note_at_pos(ui.mpos, tool.elements)
	if hovered_note != unsafe { nil } {
		ui.set_cursor(.resize_all)
	} else {
		ui.set_cursor(.default)
	}
}

fn (mut tool ToolDeleteNotes) delete_all_in_queue() {
	// Remove all hovered notes
	for note in tool.queue {
		tool.delete_note(note)
	}
	
	// Clear queue
	tool.queue.clear()
	tool.queue_colors.clear()
}

fn (mut tool ToolDeleteNotes) cancel_deletion() {
	// Restore colors
	for i, mut note in tool.queue {
		note.color = tool.queue_colors[i] or { Color.hex("#ff0000") }
	}
	
	// Clear queue
	tool.queue.clear()
	tool.queue_colors.clear()
}

