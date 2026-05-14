module context

import gg
import sokol.sapp { MouseCursor }

import std.geom2 { Vec2 }
import std { Color }
import uilib { UI }
import audio.objs { Note }

@[heap]
pub struct DlNoteEditorToolContext {
	pub mut:
	// Cursor
	set_cursor             fn (cusror MouseCursor)                                                 @[required]
	get_cursor             fn () MouseCursor                                                       @[required]
	
	// Draw calls
	draw_rect              fn (from Vec2, size Vec2, config uilib.RectConfig)                      @[required]
	draw_text              fn (pos Vec2, text string, config gg.TextCfg)                           @[required]
	draw_circle            fn (center Vec2, radius f64, color Color, empty bool)                   @[required]
	draw_line_with_config  fn (a Vec2, b Vec2, config gg.PenConfig)                                @[required]
	draw_icon              fn (icon string, from Vec2, size Vec2, color Color)                     @[required]
	
	// Note Editor Controls
	create_note            fn (note Note) &Note                                                    @[required]
	delete_note            fn (note &Note)                                                         @[required]
	force_update_note      fn (note &Note)                                                         @[required]
}
