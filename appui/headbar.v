module appui

import gg
import hash

import std.geom2 { Vec2 }
import uilib { UI, ActionList, Action, Button }

pub struct HeaderAction {
	pub mut:
	is_seperator    bool
	name            string
	tag             string
	hotkey          string
	sub_actions     []HeaderAction
	disabled        bool
	
	user_data       voidptr
	on_selected     ?fn (tag string, user_data voidptr)
}

fn (actions []HeaderAction) to_ui_action_list(from Vec2, size Vec2) ActionList {
	mut ui_actions := []Action{}
	for a in actions {
		ui_actions << Action{
			is_seperator:   a.is_seperator
			name:           a.name
			tag:            a.tag
			hotkey:         a.hotkey
			disabled:       a.disabled
			
			user_data:      a.user_data
			on_selected:    a.on_selected
		}
	}
	return ActionList{
		from: from
		size: size
		actions: ui_actions
	}
}

@[heap]
pub struct Header {
	pub mut:
	height          f64                 = 24.0
	
	option_hovered  int                 = -1
	option_open     int                 = -1
	options         map[string][]HeaderAction
	action_list     ?ActionList
	project_name    string              = "unnamed.lmnj*"
	
	user_actions    ActionList          = ActionList{}
	user_btn        Button              = Button{
		title: "."
		// This Buttons does NOTHING when pressed
	}
}


pub fn (mut header Header) init(mut ui UI) {
	// Connect event hooks
	ui.on_mouse_down << fn [mut header] (mut ui UI, mpos Vec2) ! {
		header.on_mouse_down(mut ui, mpos)!
	}
	ui.on_mouse_move << fn [mut header] (mut ui UI, mpos Vec2, mdelta Vec2) ! {
		header.on_mouse_move(mut ui, mpos, mdelta)!
	}
	
	// > Connect hook through ui to update user name
	ui.hooks["on-username-change"] = fn [mut header, mut ui] (name_ptr voidptr) {
		name := unsafe { cstring_to_vstring(name_ptr) }
		header.user_btn.title = if name == "" { "." } else { name.substr(0, 1) }
		// > Pick random color for user by hashing user name and moduling it down to max len in color list in ui
		color := ui.style.colors_users[hash.sum64_string(name, 0) % u64(ui.style.colors_users.len)]
		header.user_btn.color_primary = color
		header.user_btn.color_secondary = color.darken(0.05)
	}
	
	// Popup user actions on press
	header.user_btn
}


pub fn (mut header Header) draw(mut ui UI) {
	header_width := ui.get_window_size().x
	
	// Draw project name
	project_name_pos := Vec2{header_width * 0.5, header.height * 0.5}
	ui.ctx.draw_text(
		int(project_name_pos.x), int(project_name_pos.y),
		header.project_name,
		color: ui.style.color_grey.get_gx()
		size: ui.style.font_size
		align: .center
		vertical_align: .middle
		family: ui.style.font_regular
	)
	
	// Draw header seperator
	ui.ctx.draw_line(
		f32(0.0), f32(header.height - 0.5),
		f32(header_width), f32(header.height - 0.5),
		ui.style.color_panel.get_gx()
	)
	
	// Draw options
	mut option_x := 0.0
	mut i := 0
	for title, _ in header.options {
		width := ui.ctx.text_width(title) + ui.style.strong_padding
		
		// > Draw hover background
		if i == header.option_hovered {
			ui.ctx.draw_rect_filled(
				f32(option_x), f32(0.0),
				f32(width), f32(header.height),
				ui.style.color_panel.get_gx()
			)
			ui.cursor = .pointing_hand
		}
		// > Draw option title
		ui.ctx.draw_text(
			int(option_x + width * 0.5), int(project_name_pos.y),
			title,
			color: ui.style.color_text.get_gx()
			size: ui.style.font_size
			align: .center
			vertical_align: .middle
			family: ui.style.font_bold
		)
		
		// > Draw actions if open
		if header.option_open == i && header.action_list != none {
			header.action_list.draw(mut ui)
		}
		
		option_x += width
		i++
	}
	
	// Draw User Button
	user_btn_size := header.height - ui.style.padding
	half_padding := ui.style.padding * 0.5
	header.user_btn.from = ui.top_right() + Vec2{-user_btn_size - half_padding, half_padding}
	header.user_btn.size = Vec2.v(user_btn_size)
	header.user_btn.rounding = user_btn_size / 2.0
	header.user_btn.draw(mut ui)
}


pub fn (mut header Header) event(mut ui UI, event &gg.Event) ! {
	if header.action_list != none {
		header.action_list.event(mut ui, event)!
	}
	
	header.user_btn.event2(mut ui, event)!
}


// ===== EVENT HOOKS =====

pub fn (mut header Header) on_mouse_down(mut ui UI, _ Vec2) ! {
	if header.option_hovered != -1 {
		header.option_open = header.option_hovered
		option_tag := header.options.keys()[header.option_hovered] or { return }
		x, _ := header.get_option_dimensions(ui, header.option_open)
		header.action_list = (header.options[option_tag] or { return }).to_ui_action_list(
			Vec2{x, header.height},
			Vec2{160.0, 0.0}
		)
	} else {
		header.option_open = -1
		header.action_list = none
	}
}

pub fn (mut header Header) on_mouse_move(mut ui UI, mpos Vec2, _ Vec2) ! {
	header.option_hovered = -1
	
	for i in 0..header.options.len {
		x, width := header.get_option_dimensions(ui, i)
		
		if mpos.y >= 0.0 && mpos.y < header.height && mpos.x >= x  && mpos.x < x + width {
			header.option_hovered = i
		}
	}
}



// ===== UTILITY =====

pub fn (header Header) get_option_dimensions(ui UI, id int) (f64, f64) {
	mut x := 0.0
	for i in 0..id {
		title := header.options.keys()[i] or { break }
		width := ui.ctx.text_width(title) // + ui.style.strong_padding
		x += width
	}
	
	title := header.options.keys()[id] or { return 0.0, 0.0 }
	width := ui.ctx.text_width(title) + ui.style.strong_padding
	
	return x, width
}

