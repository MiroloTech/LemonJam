module tools

import gg
// import sokol.sapp

import uilib { UI, NoteUI }
// import std.geom2 { Vec2 }
import std { Color }

@[heap]
pub struct ToolCutNotes {
	EditorTool[NoteUI]
	
	pub:
	icon                    string            = "tool-cut"
	color                   Color             = Color.hex("#56a2e8")
}

pub fn (mut tool ToolCutNotes) event(mut ui UI, event &gg.Event) {
	
}

pub fn (mut tool ToolCutNotes) draw(mut ui UI) {
	
}

