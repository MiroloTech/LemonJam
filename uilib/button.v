module uilib

import gg

import std { Color }
import std.geom2 { Vec2, Rect2 }

pub enum ButtonType {
	solid
	outline
	grey
	text
	flat
	dark
}

// TODO: Add icon support
// TODO: Implement proper wrapping of text

pub struct Button {
	pub mut:
	from             Vec2
	size             Vec2
	title            string
	is_pressed       bool
	is_hovered       bool
	typ              ButtonType                    = .solid
	align            gg.HorizontalAlign            = .center
	disabled         bool
	
	user_data        voidptr                       = unsafe { nil }
	on_pressed       ?fn (user_data voidptr)
	
	color_primary    ?Color
	color_secondary  ?Color
	font_size        ?int
	rounding         ?f64
}

pub fn (btn Button) draw(mut ui UI) {
	if btn.is_hovered {
		if btn.disabled {
			ui.set_cursor(.not_allowed)
		} else {
			ui.set_cursor(.pointing_hand)
		}
	}
	
	if btn.disabled {
		btn.draw_grey(mut ui)
	} else {
		match btn.typ {
			.solid { btn.draw_solid(mut ui) }
			.outline { btn.draw_outline(mut ui) }
			.grey { btn.draw_grey(mut ui) }
			.dark { btn.draw_dark(mut ui) }
			.text {
				color_main := btn.color_primary or { ui.style.color_text }
				color_hovered := btn.color_secondary or { ui.style.color_text }
				color_pressed := (btn.color_secondary or { ui.style.color_text }).darken(0.2)
				color_disabled := ui.style.color_grey
				btn.draw_colored_btn_text(btn.title, mut ui, if btn.disabled {
						color_disabled
					} else {
						if btn.is_pressed {
							color_pressed
						} else {
							if btn.is_hovered {
								color_hovered
							} else {
								color_main
							}
						}
					}
				)
			}
			.flat {
				if btn.is_hovered || btn.is_pressed {
					btn.draw_solid(mut ui)
				} else {
					btn.draw_btn_text(btn.title, mut ui)
				}
			}
		}
	}
}

pub fn (mut btn Button) event(mut ui UI, event &gg.Event) {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	rect := Rect2{btn.from, btn.from + btn.size}
	btn.is_hovered = rect.is_point_inside(mpos)
	
	if btn.disabled {
		btn.is_hovered = false
		btn.is_pressed = false
		return
	}
	
	if event.typ == .mouse_down && btn.is_hovered && !btn.is_pressed {
		btn.is_pressed = true
		if btn.on_pressed != none {
			btn.on_pressed(btn.user_data)
		}
	}
	
	if event.typ == .mouse_up && btn.is_pressed {
		btn.is_pressed = false
	}
}


pub fn (mut btn Button) event2(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	rect := Rect2{btn.from, btn.from + btn.size}
	btn.is_hovered = rect.is_point_inside(mpos)
	
	if btn.disabled {
		btn.is_hovered = false
		btn.is_pressed = false
		return
	}
	
	if event.typ == .mouse_down && btn.is_hovered && !btn.is_pressed {
		btn.is_pressed = true
		if btn.on_pressed != none {
			btn.on_pressed(btn.user_data)
			return surpress_event()
		}
	}
	
	if event.typ == .mouse_up && btn.is_pressed {
		btn.is_pressed = false
	}
}


fn (btn Button) draw_solid(mut ui UI) {
	color := if btn.is_hovered && !btn.disabled { btn.color_secondary or { ui.style.color_primary_dark } } else { btn.color_primary or { ui.style.color_primary } }
	rounding := if btn.rounding != none { btn.rounding } else { ui.style.rounding }
	ui.ctx.draw_rounded_rect_filled(
		f32(btn.from.x), f32(btn.from.y),
		f32(btn.size.x), f32(btn.size.y),
		f32(rounding),
		color.get_gx()
	)
	
	// Text
	btn.draw_btn_text(btn.title, mut ui)
}

fn (btn Button) draw_outline(mut ui UI) {
	color := if btn.is_hovered && !btn.disabled { btn.color_secondary or { ui.style.color_primary_dark } } else { btn.color_primary or { ui.style.color_primary } }
	rounding := if btn.rounding != none { btn.rounding } else { ui.style.rounding }
	
	// Outline
	ui.ctx.draw_rounded_rect_filled(
		f32(btn.from.x), f32(btn.from.y),
		f32(btn.size.x), f32(btn.size.y),
		f32(rounding),
		color.get_gx()
	)
	
	// Body
	ui.ctx.draw_rounded_rect_filled(
		f32(btn.from.x + ui.style.outline_size),       f32(btn.from.y + ui.style.outline_size),
		f32(btn.size.x - ui.style.outline_size * 2.0), f32(btn.size.y - ui.style.outline_size * 2.0),
		f32(rounding - ui.style.outline_size),
		ui.style.color_panel.get_gx()
	)
	
	// Text
	btn.draw_btn_text(btn.title, mut ui)
}

fn (btn Button) draw_grey(mut ui UI) {
	color := if btn.is_hovered && !btn.disabled { ui.style.color_panel.brighten(0.1) } else { ui.style.color_panel }
	rounding := if btn.rounding != none { btn.rounding } else { ui.style.rounding }
	ui.ctx.draw_rounded_rect_filled(
		f32(btn.from.x), f32(btn.from.y),
		f32(btn.size.x), f32(btn.size.y),
		f32(rounding),
		color.get_gx()
	)
	
	// Text
	btn.draw_btn_text(btn.title, mut ui)
}

fn (btn Button) draw_dark(mut ui UI) {
	color := if btn.is_hovered && !btn.disabled { btn.color_secondary or { ui.style.color_grey } } else { btn.color_primary or { ui.style.color_bg } }
	rounding := if btn.rounding != none { btn.rounding } else { ui.style.rounding }
	ui.ctx.draw_rounded_rect_filled(
		f32(btn.from.x), f32(btn.from.y),
		f32(btn.size.x), f32(btn.size.y),
		f32(rounding),
		color.get_gx()
	)
	
	// Text
	btn.draw_btn_text(btn.title, mut ui)
}

fn (btn Button) draw_btn_text(text string, mut ui UI) {
	btn.draw_colored_btn_text(text, mut ui, ui.style.color_text)
}

fn (btn Button) draw_colored_btn_text(text string, mut ui UI, color Color) {
	text_pos := match btn.align {
		.left   { btn.from + Vec2{ui.style.padding * 2.0, btn.size.y * 0.5} }
		.center { btn.from + btn.size * Vec2{0.5, 0.5} }
		.right  { btn.from + Vec2{btn.size.x - ui.style.padding * 2.0, btn.size.y * 0.5} }
	}
	
	ui.ctx.draw_text(
		int(text_pos.x), int(text_pos.y),
		text,
		color: color.get_gx()
		size: btn.font_size or { ui.style.font_size }
		align: btn.align
		vertical_align: .middle
		max_width: int(btn.size.x)
		family: ui.style.font_regular
	)
}
