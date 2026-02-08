module tools

import gg
import sokol.sapp

import uilib { UI, NoteUI }
import std { Color }

@[heap]
pub struct ToolCutNotes {
	pub:
	icon                    string            = "tool-cut"
	color                   Color             = Color.hex("#56a2e8")
	
	pub mut:
	conv_note2world         ToolFnNoteToWorld = unsafe { nil }
	conv_world2note         ToolFnWorldToNote = unsafe { nil }
	
	note_uis                []&NoteUI
}

pub fn (tool ToolCutNotes) get_cursor() sapp.MouseCursor {
	return .default
}
	
	
pub fn (mut tool ToolCutNotes) on_ui_event(mut ui UI, event &gg.Event) {
	
}

pub fn (mut tool ToolCutNotes) draw(mut ui UI) {
	
}

