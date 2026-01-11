module appui

import gg

import std.geom2 { Vec2 }
import uilib { UI, ActionList, Action }

pub struct HeaderAction {
	pub mut:
	is_seperator    bool
	name            string
	tag             string
	hotkey          string
	sub_actions     []HeaderAction
	
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

pub struct Header {
	pub mut:
	height          f64                 = 24.0
	
	option_hovered  int                 = -1
	option_open     int                 = -1
	options         map[string][]HeaderAction
	action_list     ?ActionList
	project_name    string              = "unnamed.lmnj*"
}

pub fn (header Header) draw(mut ui UI) {
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
}


pub fn (mut header Header) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	header.option_hovered = -1
	
	mut x_positions := []f64{}
	mut option_x := 0.0
	mut i := 0
	for title, _ in header.options {
		width := ui.ctx.text_width(title) + ui.style.strong_padding
		x_positions << option_x
		
		if mpos.y >= 0.0 && mpos.y < header.height && mpos.x >= option_x  && mpos.x < option_x + width {
			header.option_hovered = i
			break
		}
		
		option_x += width
		i++
	}
	
	if event.typ == .mouse_down {
		if header.option_hovered != -1 {
			header.option_open = header.option_hovered
			option_tag := header.options.keys()[header.option_hovered] or { return }
			header.action_list = (header.options[option_tag] or { return }).to_ui_action_list(
				Vec2{x_positions[i] or { 0.0 }, header.height},
				Vec2{160.0, 0.0}
			)
		} else {
			header.option_open = -1
			header.action_list = none
		}
	}
	
	if header.action_list != none {
		header.action_list.event(mut ui, event)!
	}
}
