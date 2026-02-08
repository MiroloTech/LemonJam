module tools

import gg
import sokol.sapp

import uilib { UI, NoteUI }
import std { Color }

@[heap]
pub struct ToolPlaceNotes {
	pub:
	icon                    string            = "tool-paint"
	color                   Color             = Color.hex("#32a783")
	
	pub mut:
	conv_note2world         ToolFnNoteToWorld = unsafe { nil }
	conv_world2note         ToolFnWorldToNote = unsafe { nil }
	
	note_uis                []&NoteUI
}

pub fn (tool ToolPlaceNotes) get_cursor() sapp.MouseCursor {
	return .default
}
	
	
pub fn (mut tool ToolPlaceNotes) on_ui_event(mut ui UI, event &gg.Event) {
	
}

pub fn (mut tool ToolPlaceNotes) draw(mut ui UI) {
	
}

