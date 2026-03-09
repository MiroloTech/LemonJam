module tools

import gg
// import sokol.sapp

import uilib { UI, NoteUI }
// import std.geom2 { Vec2 }
import std { Color }

@[heap]
pub struct ToolPlaceNotes {
	EditorTool[NoteUI]
	
	pub:
	icon                    string            = "tool-paint"
	color                   Color             = Color.hex("#32a783")
}

pub fn (mut tool ToolPlaceNotes) event(mut ui UI, event &gg.Event) {
	
}

pub fn (mut tool ToolPlaceNotes) draw(mut ui UI) {
	
}

