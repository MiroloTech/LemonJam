module uilib

import gg

import std.visual as ggp
import std.geom2 { Vec2, Rect2 }

pub struct Action {
	pub mut:
	is_seperator     bool
	name             string
	tag              string
	hotkey           string
	sub_actions      []Action
	disabled         bool
	
	user_data       voidptr
	on_selected     ?fn (tag string, user_data voidptr)
}

pub fn (actions []Action) get_height(ui UI) f64 {
	mut height := ui.style.list_gap
	for act in actions {
		if act.is_seperator {
			height += ui.style.seperator_height
		} else {
			height += f64(ui.style.font_size) + ui.style.list_gap
		}
	}
	return height - ui.style.list_gap
}


pub struct ActionList {
	pub mut:
	from             Vec2
	size             Vec2
	actions          []Action
	
	action_hovered   int        = -1
}

pub fn (al ActionList) draw(mut ui UI) {
	// TODO: sub-options
	offset := 4.0
	mut from := al.from + Vec2{0.0, offset}
	if from.x < offset {
		from.x = offset
	}
	mut y := from.y
	height := al.actions.get_height(ui)
	
	// Draw action list background
	/*
	ui.ctx.draw_rect_filled(
		f32(al.from.x), f32(al.from.y),
		f32(al.size.x), f32(height),
		ui.style.color_panel.get_gx()
	)
	*/
	ui.draw_rect(
		from,
		Vec2{al.size.x, height},
		
		fill_color: ui.style.color_bg
		outline_color: ui.style.color_panel
		inset: -offset
		outline: 1.0
		radius: 0.0
	)
	
	// Draw actions
	for i, action in al.actions {
		if action.is_seperator {
			// > Draw seperator
			seperator_y := y + ui.style.seperator_height * 0.5
			ggp.draw_thick_line(
				mut ui.ctx,
				f32(from.x), f32(seperator_y),
				f32(from.x + al.size.x), f32(seperator_y),
				f32(1.0),
				ui.style.color_panel.get_gx()
			)
			
			y += ui.style.seperator_height
		} else {
			// > Draw hover background
			if i == al.action_hovered && !action.disabled {
				ui.ctx.draw_rect_filled(
					f32(from.x), f32(y),
					f32(al.size.x), f32(f64(ui.style.font_size) + ui.style.list_gap),
					ui.style.color_panel.brighten(0.05).get_gx()
				)
			}
			
			// > Draw option name
			ui.ctx.draw_text(
				int(from.x + ui.style.padding), int(y + f64(ui.style.font_size) * 0.5 + 2.0),
				action.name,
				color: if action.disabled { ui.style.color_grey.get_gx() } else { ui.style.color_text.get_gx() }
				size: ui.style.font_size
				align: .left
				vertical_align: .middle
				max_width: int(al.size.x)
				family: ui.style.font_regular
			)
			
			// > Draw option hotkey
			ui.ctx.draw_text(
				int(from.x + al.size.x - ui.style.padding), int(y + f64(ui.style.font_size) * 0.5 + 2.0),
				action.hotkey,
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				max_width: int(al.size.x)
				family: ui.style.font_regular
			)
			
			y += f64(ui.style.font_size) + ui.style.list_gap
		}
	}
}

pub fn (mut al ActionList) event(mut ui UI, event &gg.Event) ! {
	offset := 1.0
	from := al.from + Vec2{offset, 0.0}
	mut y := from.y + offset
	// height := al.actions.get_height(ui)
	mpos := Vec2{event.mouse_x, event.mouse_y}
	al.action_hovered = -1
	
	// Draw actions
	for i, action in al.actions {
		if action.is_seperator {
			y += ui.style.seperator_height
		} else {
			height := f64(ui.style.font_size) + ui.style.list_gap
			if from.x <= mpos.x && mpos.x < from.x + al.size.x  &&  y <= mpos.y && mpos.y < y + height  &&  !action.disabled {
				al.action_hovered = i
			}
			
			y += height
		}
	}
	
	// Call function for appropriate action when pressed
	if event.typ == .mouse_down && al.action_hovered != -1 {
		action := al.actions[al.action_hovered] or { return }
		if !action.is_seperator && action.on_selected != none {
			action.on_selected(action.tag, action.user_data)
			return surpress_event()
		}
	}
	
	// Surpress following event reactions
	if from.x <= mpos.x && mpos.x < from.x + al.size.x  &&  from.y <= mpos.y && mpos.y < y {
		return surpress_event()
	}
	
	// Blocks any following event notice. Enable this if clicking "away" from the menu shouldn't trigger any other thing.
	if event.typ == .mouse_down && al.action_hovered != -1 {
		return surpress_event()
	}
}
