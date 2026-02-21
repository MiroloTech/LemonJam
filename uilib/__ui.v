module uilib

import os
import log
import gg
import time
import sokol.sapp

import std.geom2 { Rect2, Vec2 }
const not_found_icon_src := $embed_file("./icons/not-found.png").to_bytes()

pub type Hook = fn (user_data voidptr)
pub type EventHook = fn (mut ui UI) !

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
	cursor_locked       bool
	icons               map[string]&gg.Image
	not_found_icon      &gg.Image             = unsafe { nil }
	mpos                Vec2                  = Vec2.zero()
	
	hooks               map[string]Hook
	
	actions             map[string]string                // Map of custom keyboard-actions, written in standart key shortcut format, i.e. "save": "ctrl+s"
	on_action_press     map[string][]EventHook
	on_action_release   map[string][]EventHook
	on_mouse_move       []fn (mut ui UI, mpos Vec2, mdelta Vec2) !
	on_mouse_down       []fn (mut ui UI, mpos Vec2) !
	on_mouse_up         []fn (mut ui UI, mpos Vec2) !
	on_event            []fn (mut ui UI, event Event) !  // NOTICE : Events surpressed at on_mouse_move, on_action_press, etc. DON'T block on_event; on_eevnt is called after all other event hooks
	
	popups              []Popup
}

pub fn (mut ui UI) set_cursor(cursor sapp.MouseCursor) {
	if !ui.cursor_locked {
		ui.cursor = cursor
	}
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
	// Update delta time
	ui.delta = ui.timer.elapsed().seconds()
	ui.timer.restart()
	
	sapp.set_mouse_cursor(ui.cursor)
	ui.set_cursor(.default)
	ui.cursor_locked = false
	
	// Draw popups seperately
	if ui.popups.len > 0 {
		// > Draw darkened BG
		ui.draw_rect(
			ui.top_left(),
			ui.bottom_right(),
			fill_color: ui.style.color_bg.alpha(0.5)
		)
		
		// > Draw popups
		for mut popup in ui.popups {
			popup.draw(mut ui)
		}
		
		// > Re-Update cursor
		sapp.set_mouse_cursor(ui.cursor)
	}
}

pub fn (mut ui UI) event(event &gg.Event) ! {
	// Update UI
	ui.mpos = Vec2{event.mouse_x, event.mouse_y}
	
	// Recreate event in own system
	ui_event := Event{
		frame_count:    event.frame_count
		typ:            event.typ
		mpos:           Vec2{event.mouse_x, event.mouse_y}
		mdelta:         Vec2{event.mouse_dx, event.mouse_dy}
		key_repeat:     event.key_repeat
		char_code:      event.char_code
		key_code:       event.key_code
		window_size:    Vec2{f64(event.window_width), f64(event.window_height)}
	}
	
	if ui.popups.len > 0 {
		for mut popup in ui.popups {
			popup.event(mut ui, event) or { break }
		}
		return surpress_event()
	}
	
	// Keyboard actions
	if event.typ == .key_down || event.typ == .key_up {
		// > Collect hook functions for specific event typ
		mut hook_map := map[string][]EventHook{}
		if event.typ == .key_down {
			hook_map = ui.on_action_press.clone() // WARNING : IDK what this does since I don't know how lambda functions look like on the stack
		} else if event.typ == .key_up {
			hook_map = ui.on_action_release.clone()
		}
		
		for action, action_code in ui.actions {
			if event_to_action_code(event) == action_code.to_lower() {
				hooks := hook_map[action] or { [] }
				for hook in hooks {
					hook(mut ui) or {
						if !(err is EventSurpressError) { log.warn("Failed to call specific hook on action '${action}' : ${err}") }
						break
					}
				}
			}
		}
	}
	
	// Mouse actions
	if event.typ == .mouse_move || event.typ == .mouse_down || event.typ == .mouse_up {
		mpos := Vec2{event.mouse_x, event.mouse_y}
		mdelta := Vec2{event.mouse_dx, event.mouse_dy}
		match event.typ {
			.mouse_move {
				for hook in ui.on_mouse_move {
					hook(mut ui, mpos, mdelta) or {
						if !(err is EventSurpressError) { log.warn("Failed to call specific hook on mouse move : ${err}") }
						break
					}
				}
			}
			.mouse_down {
				for hook in ui.on_mouse_down {
					hook(mut ui, mpos) or {
						if !(err is EventSurpressError) { log.warn("Failed to call specific hook on mouse down : ${err}") }
						break
					}
				}
			}
			.mouse_up {
				for hook in ui.on_mouse_up {
					hook(mut ui, mpos) or {
						if !(err is EventSurpressError) { log.warn("Failed to call specific hook on mouse up : ${err}") }
						break
					}
				}
			}
			else {  }
		}
	}
	
	// General Event
	for hook in ui.on_event {
		hook(mut ui, ui_event) or {
			if !(err is EventSurpressError) { log.warn("Failed to call specific hook on general event : ${err}") }
			break
		}
	}
}

pub fn (mut ui UI) call_hook(tag string, data voidptr) ! {
	hook := ui.hooks[tag] or {
		log.error("Tried calling inexistant hook : ${tag}")
		return error("Tried calling inexistant hook : ${tag}")
	}
	hook(data)
	// log.info("Hook called : ${tag}")
}


pub fn event_to_action_code(event &gg.Event) string {
	if event.typ == .key_down {
		
	}
	return ""
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
pub fn (ui UI) center() Vec2 {
	return ui.get_window_size() * Vec2{0.5, 0.5}
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

