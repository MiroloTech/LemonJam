module note_editor_tools

import gg

import uilib { UI, NoteUI }
import audio.objs { Pattern, Instrument }
import std { Color }
import std.geom2 { Vec2 }

pub type ToolFnGridToWorld = fn (time f64, id int) Vec2
pub type ToolFnWorldToGrid = fn (world_pos Vec2) (f64, int)

// TODO : Fix / report bug, where T is somehow both interpreted as NoteUI and as &gg.Event


pub interface NoteEditorToolSkeleton {
	icon                  string
	color                 Color
	is_visible            bool
	
	mut:
	hotkey                string
	elements              []&NoteUI
	pattern               &Pattern
	current_color         Color
	current_instrument    &Instrument
	
	grid_world_conv       GridWorldConverter
	
	create_note           fn (note &NoteUI)
	delete_note           fn (note &NoteUI)
	
	draw(mut ui UI)
	event(mut ui UI, event &gg.Event)
}


pub struct GridWorldConverter {
	pub mut:
	grid_to_world         ToolFnGridToWorld     = fn (time f64, id int) Vec2 { return Vec2{} }
	world_to_grid         ToolFnWorldToGrid     = fn (pos Vec2) (f64, int) { return 0.0, 0 }
}


@[heap]
pub struct NoteEditorTool implements NoteEditorToolSkeleton {
	pub:
	icon                  string
	color                 Color
	is_visible            bool                  = true
	
	pub mut:
	hotkey                string
	elements              []&NoteUI
	pattern               &Pattern              = unsafe { nil }
	current_color         Color
	current_instrument    &Instrument           = unsafe { nil }
	
	grid_world_conv       GridWorldConverter
	
	create_note           fn (note &NoteUI)    = unsafe { nil }
	delete_note           fn (note &NoteUI)    = unsafe { nil }
}

pub fn (mut editor_tool NoteEditorTool) draw(mut ui UI) {
	
}

pub fn (mut editor_tool NoteEditorTool) event(mut ui UI, event &gg.Event) {
	
}

