module uilib

import gg
import clipboard

import std { Color }
import std.geom2 { Vec2, Rect2 }


pub struct LineEdit {
	pub mut:
	from                        Vec2
	size                        Vec2
	text                        string
	placeholder                 string                        = "..."
	is_focused                  bool
	is_hovered                  bool
	is_dragging                 bool
	disabled                    bool
	mono                        bool
	
	caret_pos                   int
	selection_start             int                           = -1
	
	user_data                   voidptr                       = unsafe { nil }
	on_change                   ?fn (text string, user_data voidptr)
	on_submitted                ?fn (text string, user_data voidptr)
	
	underline_color             ?Color
	underline_color_focused     ?Color
}

// TODO : Fix space behaviour with non-mono fonts ( spaces are larger, and the letter after the space is smaller, when selecting )
// TODO : Implement Ctrl + Edit
// TODO : Implement disabled state

pub fn (edit LineEdit) draw(mut ui UI) {
	// Draw bottom focus line
	focus_line_color := if edit.is_focused { edit.underline_color_focused or { ui.style.color_primary } } else { edit.underline_color or { ui.style.color_bg.brighten(0.05) } }
	ui.ctx.draw_rect_filled(
		f32(edit.from.x), f32(edit.from.y + edit.size.y - 2.0),
		f32(edit.size.x), f32(2.0),
		focus_line_color.get_gx()
	)
	
	caret_height := f64(ui.style.font_size)
	caret_start_y := edit.from.y + edit.size.y * 0.5 - caret_height * 0.5
	
	// Draw selection
	if edit.selection_start != -1 {
		sel_pos_from := edit.get_pos_at_char(int_min(edit.caret_pos, edit.selection_start), mut ui)
		sel_pos_to := edit.get_pos_at_char(int_max(edit.caret_pos, edit.selection_start), mut ui)
		
		ui.ctx.draw_rounded_rect_filled(
			f32(edit.from.x + sel_pos_from + ui.style.padding), f32(caret_start_y),
			f32(sel_pos_to - sel_pos_from), f32(caret_height),
			f32(ui.style.rounding * 0.5),
			ui.style.color_bg.brighten(0.1).get_gx()
		)
	}
	
	// Draw text
	mut text_pos := Vec2{edit.from.x + ui.style.padding, edit.from.y + edit.size.y * 0.5}
	ui.ctx.draw_text(
		int(text_pos.x), int(text_pos.y),
		(if edit.text == "" { edit.placeholder } else { edit.text }),
		color: if edit.text == "" { ui.style.color_grey.get_gx() } else { ui.style.color_text.get_gx() }
		size: ui.style.font_size
		vertical_align: .middle
		max_width: int(edit.size.x)
		family: edit.get_font(ui)
	)
	
	// Draw caret
	if edit.is_focused {
		ui.ctx.draw_rect_filled(
			f32(edit.from.x + edit.get_pos_at_char(edit.caret_pos, mut ui) + ui.style.padding - 1.0), f32(caret_start_y),
			f32(1.0), f32(caret_height),
			ui.style.color_text.get_gx()
		)
	}
	
	// Update mouse cursor
	if edit.is_hovered {
		ui.cursor = .ibeam
	}
}

fn (edit LineEdit) get_pos_at_char(char_id int, mut ui UI) f64 {
	ui.ctx.set_text_cfg(
		size: ui.style.font_size
		vertical_align: .middle
		max_width: int(edit.size.x)
		family: edit.get_font(ui)
	)
	return f64(ui.ctx.text_width(edit.text.substr(0, char_id)))
}

fn (edit LineEdit) get_text_width(text string, mut ui UI) f64 {
	ui.ctx.set_text_cfg(
		size: ui.style.font_size
		vertical_align: .middle
		max_width: int(edit.size.x)
		family: edit.get_font(ui)
	)
	return f64(ui.ctx.text_width(text))
}

fn (edit LineEdit) get_font(ui UI) string {
	if edit.mono {
		return ui.style.font_mono
	}
	return ui.style.font_regular
}


pub fn (mut edit LineEdit) event(mut ui UI, event &gg.Event) {
	// Update hover state
	mpos := Vec2{event.mouse_x, event.mouse_y}
	rect := Rect2{edit.from, edit.from + edit.size}
	edit.is_hovered = rect.is_point_inside(mpos)
	
	if event.typ == .mouse_down {
		edit.is_focused = edit.is_hovered
		edit.selection_start = -1
		
		// > Determine caret position at mouse on focus
		if edit.is_focused {
			edit.caret_pos = edit.get_caret_pos_at_world_pos(mpos, mut ui)
			edit.selection_start = edit.caret_pos
		}
		edit.is_dragging = true
	}
	if event.typ == .mouse_up {
		edit.is_dragging = false
		if edit.caret_pos == edit.selection_start {
			edit.selection_start = -1
		}
	}
	
	if !edit.is_focused { return }
	
	// > Select text with dragging
	if edit.is_dragging {
		target := edit.get_caret_pos_at_world_pos(mpos, mut ui)
		edit.caret_pos = target
	}
	
	if event.typ == .key_down {
		// Move caret left and right
		if event.key_code == .left && edit.caret_pos > 0 {
			edit.caret_pos -= 1
			if event.modifiers != 0b1 {
				edit.selection_start = -1
			}
		}
		if event.key_code == .right && edit.caret_pos < edit.text.len {
			edit.caret_pos += 1
			if event.modifiers != 0b1 {
				edit.selection_start = -1
			}
		}
		if event.key_code == .left_shift && edit.selection_start == -1 {
			edit.selection_start = edit.caret_pos
		}
		
		// Delete text
		if event.key_code == .backspace {
			edit.delete(edit.caret_pos - 1, edit.caret_pos)
			edit.trigger_change()
		}
		if event.key_code == .delete {
			edit.delete(edit.caret_pos, edit.caret_pos + 1)
			edit.trigger_change()
		}
		
		// Paste text
		if event.key_code == .v && event.modifiers & 0b10 == 0b10 {
			mut cb := clipboard.new()
			edit.insert(cb.paste())
			cb.destroy()
		}
		
		// Submit text
		if event.key_code == .enter {
			edit.is_focused = false
			edit.is_dragging = false
			edit.selection_start = -1
			edit.caret_pos = 0
			if edit.on_submitted != none {
				edit.on_submitted(edit.text, edit.user_data)
			}
		}
	}
	
	if event.typ == .key_up {
		// Fix weird selection behaviour
		if event.key_code == .left_shift {
			if edit.caret_pos == edit.selection_start {
				edit.selection_start = -1
			}
		}
	}
	
	// Type
	if event.typ == .char {
		c := u8(event.char_code).ascii_str()
		edit.insert(c)
		edit.trigger_change()
	}
}

// Inserts text at caret, or replaces selected text, if text is selected
pub fn (mut edit LineEdit) insert(text string) {
	// > Fix selection being in front of caret
	if edit.selection_start > edit.caret_pos {
		temp := edit.caret_pos
		edit.caret_pos = edit.selection_start
		edit.selection_start = temp
	}
	
	if edit.selection_start != -1 && edit.selection_start != edit.caret_pos {
		sel_from := int_min(edit.selection_start, edit.caret_pos)
		sel_to := int_max(edit.selection_start, edit.caret_pos)
		edit.text = edit.text.substr(0, sel_from) + text + edit.text.substr(sel_to, edit.text.len)
		edit.caret_pos -= sel_to - sel_from
	} else {
		edit.text = edit.text.substr(0, edit.caret_pos) + text + edit.text.substr(edit.caret_pos, edit.text.len)
	}
	edit.selection_start = -1
	edit.caret_pos += text.len
}

// Removes the text in the given range
pub fn (mut edit LineEdit) delete(from int, to int) {
	if edit.selection_start != -1 && edit.selection_start != edit.caret_pos {
		sel_from := int_min(edit.selection_start, edit.caret_pos)
		sel_to := int_max(edit.selection_start, edit.caret_pos)
		edit.text = edit.text.substr(0, sel_from) + edit.text.substr(sel_to, edit.text.len)
		edit.caret_pos = sel_from
	} else {
		if from < 0 || to > edit.text.len { return }
		edit.text = edit.text.substr(0, from) + edit.text.substr(to, edit.text.len)
		edit.caret_pos -= edit.caret_pos - from
	}
	edit.selection_start = -1
}

pub fn (mut edit LineEdit) trigger_change() {
	if edit.on_change != none {
		edit.on_change(edit.text, edit.user_data)
	}
}

fn (edit LineEdit) get_caret_pos_at_world_pos(pos Vec2, mut ui UI) int {
	mut closest_dist := edit.from.x + ui.style.padding + edit.get_pos_at_char(0, mut ui)
	mut closest_pos := 0
	for i in 0..(edit.text.len + 1) {
		x := edit.from.x + ui.style.padding + edit.get_pos_at_char(i, mut ui)
		dist := f64_abs(pos.x - x)
		if dist < closest_dist {
			closest_dist = dist
			closest_pos = i
		}
	}
	return closest_pos
}
