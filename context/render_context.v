module context

// This script contains a hand full of structs, which are given to the dynamically loaded plugins like instruments, effects, etc. to be able to easily and properly use in-app features

import gg
import sokol.sapp { MouseCursor }

import std.geom2 { Vec2 }
import std { Color }
import uilib { UI }


@[heap]
pub struct DlRenderContext {
	pub mut:
	// Draw calls
	draw_rect              fn (from Vec2, size Vec2, config uilib.RectConfig)                      @[required]
	draw_text              fn (pos Vec2, text string, config gg.TextCfg)                           @[required]
	draw_circle            fn (center Vec2, radius f64, color Color, empty bool)                   @[required]
	draw_line_with_config  fn (a Vec2, b Vec2, config gg.PenConfig)                                @[required]
	
	// Cursor
	set_cursor             fn (cusror MouseCursor)                                                 @[required]
	get_cursor             fn () MouseCursor                                                       @[required]
	
	// Window controls
	get_window_size        fn () Vec2                                                              @[required]
	get_window_scale       fn () f64                                                               @[required]
}

pub fn DlRenderContext.new(mut ui UI) &DlRenderContext {
	// mut ctx := unsafe { &DlRenderContext(malloc(sizeof(DlRenderContext))) }
	return &DlRenderContext{
		draw_rect:          fn [mut ui] (from Vec2, size Vec2, config uilib.RectConfig) {
			ui.draw_rect(from, size, config)
		}
		draw_text:          fn [mut ui] (pos Vec2, text string, config gg.TextCfg) {
			ui.ctx.draw_text(int(pos.x), int(pos.y), text, config)
		}
		draw_circle:        fn [mut ui] (center Vec2, radius f64, color Color, empty bool) {
			if empty {
				ui.ctx.draw_circle_empty(f32(center.x), f32(center.y), f32(radius), color.get_gx())
			} else {
				ui.ctx.draw_circle_filled(f32(center.x), f32(center.y), f32(radius), color.get_gx())
			}
		}
		draw_line_with_config:  fn [mut ui] (a Vec2, b Vec2, config gg.PenConfig) {
			ui.ctx.draw_line_with_config(f32(a.x), f32(a.y), f32(b.x), f32(b.y), config)
		}
		
		set_cursor:         fn [mut ui] (cursor MouseCursor) {
			ui.cursor = cursor
		}
		get_cursor:         fn [mut ui] () MouseCursor {
			return ui.cursor
		}
		
		get_window_size:    fn [mut ui] () Vec2 {
			return Vec2{ui.ctx.window_size().width, ui.ctx.window_size().height}
		}
		get_window_scale:   fn [mut ui] () f64 {
			return ui.ctx.scale
		}
	}
}
