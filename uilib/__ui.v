module uilib

import os
import log
import gg
import time
import sokol.sapp

import std.geom2 { Rect2, Vec2 }
const not_found_icon_src := $embed_file("./icons/not-found.png").to_bytes()

pub type Hook = fn (user_data voidptr)

@[heap]
pub struct UI {
	mut:
	timer               time.StopWatch        = time.new_stopwatch()
	
	pub mut:
	ctx                 &gg.Context           = unsafe { nil }
	style               Style                 = Style{}
	scissor_stack       []Rect2               = []Rect2{}
	delta               f64                   = 1.0
	cursor              sapp.MouseCursor      = .default
	icons               map[string]&gg.Image
	not_found_icon      &gg.Image             = unsafe { nil }
	
	components          []Component
	actors              []Actors
	hooks               map[string]Hook
}

pub fn (ui UI) get_window_size() Vec2 {
	win_size := ui.ctx.window_size()
	return Vec2{win_size.width, win_size.height}
}

pub fn (ui UI) get_window_rect() Rect2 {
	return Rect2{
		Vec2.zero(),
		ui.get_window_size()
	}
}

pub fn (mut ui UI) push_scissor(scissor_rect Rect2) {
	if scissor_rect.b.x < scissor_rect.a.x || scissor_rect.b.y < scissor_rect.a.y {
		// log.warn("Tried to push inverted scissor rect : ${scissor_rect}")
		ui.push_scissor(Rect2{})
		return
	}
	ui.scissor_stack << scissor_rect
	ui.ctx.scissor_rect(
		int(scissor_rect.a.x), int(scissor_rect.a.y),
		int(scissor_rect.b.x), int(scissor_rect.b.y),
	)
}

pub fn (mut ui UI) pop_scissor() {
	_ := ui.scissor_stack.pop()
	last_rect := if ui.scissor_stack.len > 0 { ui.scissor_stack.last() } else { ui.get_window_rect() }
	ui.ctx.scissor_rect(
		int(last_rect.a.x), int(last_rect.a.y),
		int(last_rect.b.x), int(last_rect.b.y),
	)
}

pub fn (mut ui UI) init() {
	ui.load_icon_list("${@VMODROOT}/uilib/icons/") or { log.error("Failed to load icon(s) : ${err}") }
	println("${ui.icons.len + 1} icons loaded")
}

pub fn (mut ui UI) draw() {
	ui.ctx.begin()
	for mut comp in ui.components {
		comp.draw(mut ui)
	}
	for mut actor in ui.actors {
		actor.draw(mut ui)
	}
	ui.ctx.end()
	
	// Update delta time
	ui.delta = ui.timer.elapsed().seconds()
	ui.timer.restart()
	
	sapp.set_mouse_cursor(ui.cursor)
	ui.cursor = .default
}

pub fn (mut ui UI) event(event &gg.Event) {
	for mut actor in ui.actors {
		actor.event(mut ui, event)
	}
}

pub fn (mut ui UI) call_hook(tag string, data voidptr) ! {
	hook := ui.hooks[tag] or {
		log.error("Tried calling inexistant hook : ${tag}")
		return error("Tried calling inexistant hook : ${tag}")
	}
	hook(data)
}


pub fn (ui UI) top_left() Vec2 {
	return Vec2{0, 0}
}

pub fn (ui UI) top_right() Vec2 {
	return Vec2{ui.get_window_size().x, 0}
}
pub fn (ui UI) bottom_left() Vec2 {
	return Vec2{0, ui.get_window_size().y}
}
pub fn (ui UI) bottom_right() Vec2 {
	return ui.get_window_size()
}


pub interface Component {
	mut:
	from             Vec2
	size             Vec2
	
	draw(mut ui UI)
}

pub interface Actors {
	mut:
	from             Vec2
	size             Vec2
	user_data        voidptr
	
	draw(mut ui UI)
	event(mut ui UI, event &gg.Event)
}


// Custom error structure to retern, when an event is surpressed
pub struct EventSurpressError {}

pub fn (esr EventSurpressError) msg() string {
	return "(ERRCODE 9) Event Surpressed! - This should never be displayed"
}

pub fn (esr EventSurpressError) code() int {
	return 9
}

pub fn surpress_event() IError {
	return EventSurpressError{}
}


// ===== ICONS =====
pub fn (mut ui UI) load_icon_list(path string) ! {
	if ui.ctx == unsafe { nil } { return error("Failed to load list of icons : ui.ctx mus be properly initialized") }
	entries := os.ls(path) or { return error("Failed to load list of icons : ${err}") }
	for entry in entries {
		p := os.join_path(path, entry)
		if !os.is_dir(p) {
			img := ui.ctx.create_image(p) or {
				log.warn("Failed to load icon : ${err}")
				continue
			}
			ui.icons[entry.all_before(".")] = &img
		}
	}
	
	// > Load not-found-image
	not_found_img := ui.ctx.create_image_from_byte_array(not_found_icon_src) or { return error("Failed to create not-found icon : ${err}") }
	ui.not_found_icon = &not_found_img
}

