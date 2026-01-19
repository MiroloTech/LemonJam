module main

import gg

// import std.geom2 { Vec2 }
import uilib { UI }
import appui { Window }

@[heap]
pub struct App {
	pub mut:
	ui                     UI                         = UI{}
	window                 Window                     = Window{}
}

fn main() {
	mut app := App{}
	app.ui.ctx = gg.new_context(
		width:            1920
		height:           1080
		bg_color:         app.ui.style.color_bg.get_gx()
		user_data:        &app
		window_title:     "LemonJam"
		init_fn:          app.init
		frame_fn:         app.frame
		event_fn:         app.event
		cleanup_fn:       app.cleanup
		sample_count:     4
	)
	app.ui.ctx.run()
}

pub fn (mut app App) init() {
	app.ui.init()
	app.window.init(mut app.ui)
}


pub fn (mut app App) frame() {
	app.ui.ctx.begin()
	app.window.frame(mut app.ui)
	app.ui.ctx.end()
	
	app.ui.draw()
}

pub fn (mut app App) event(event &gg.Event, _ voidptr) {
	app.window.event(mut app.ui, event)
	app.ui.event(event)
}

pub fn (mut app App) cleanup() {
	app.window.cleanup(mut app.ui)
}
