module note_editor_tools

import gg

// import app { Project }
// import uilib { UI, NoteUI }
// import audio.objs { Pattern, Instrument }
import std { Color }
import std.geom2 { Vec2 }
import context { DlNoteEditorToolContext }

pub type ToolFnGridToWorld = fn (time f64, id int) Vec2
pub type ToolFnWorldToGrid = fn (world_pos Vec2) (f64, int)

// TODO : Fix / report bug, where T is somehow both interpreted as NoteUI and as &gg.Event

pub interface NoteEditorToolSkeleton {
	icon                  string
	color                 Color
	
	mut:
	is_visible            bool
	hotkey                string
	ctx                   &DlNoteEditorToolContext
	
	draw()
	event(&gg.Event)
}

@[heap]
pub struct NoteEditorTool {
	// pub:
	// icon                  string
	// color                 Color
	
	pub mut:
	is_visible            bool                            = true
	hotkey                string
	ctx                   &DlNoteEditorToolContext        = unsafe { nil }
	
	// elements              []&NoteUI
	// pattern               &Pattern              = unsafe { nil }
	// current_color         Color
	// current_instrument    &Instrument           = unsafe { nil }
	// project               &Project              = unsafe { nil }
	// 
	// grid_world_conv       GridWorldConverter
	// 
	// create_note           fn (note &NoteUI)    = unsafe { nil }
	// delete_note           fn (note &NoteUI)    = unsafe { nil }
}

/*
pub fn (mut editor_tool NoteEditorTool) draw() {
	
}
*/

/*
pub fn (mut editor_tool NoteEditorTool) event(event &gg.Event) {
	
}
*/

