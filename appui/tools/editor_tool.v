module tools

import gg

import uilib { UI }
import std { Color }
import std.geom2 { Vec2 }

pub type ToolFnGridToWorld = fn (time f64, id int) Vec2
pub type ToolFnWorldToGrid = fn (world_pos Vec2) (f64, int)

pub struct EditorTool[T] {
	pub:
	icon                  string
	color                 Color
	is_visible            bool                  = true
	
	pub mut:
	hotkey                string
	elements              []&T
	
	grid_world_conv       GridWorldConverter
}

pub fn (mut editor_tool EditorTool[T]) draw(mut ui UI) {
	
}

pub fn (mut editor_tool EditorTool[T]) event(mut ui UI, event &gg.Event) {
	
}


pub interface EditorToolSkeleton[T] {
	icon                  string
	color                 Color
	is_visible            bool
	
	mut:
	hotkey                string
	elements              []&T
	
	grid_world_conv       GridWorldConverter
	
	draw(mut ui UI)
	event(mut ui UI, event &gg.Event)
}


pub struct GridWorldConverter {
	pub mut:
	grid_to_world         ToolFnGridToWorld     = fn (time f64, id int) Vec2 { return Vec2{} }
	world_to_grid         ToolFnWorldToGrid     = fn (pos Vec2) (f64, int) { return 0.0, 0 }
}

