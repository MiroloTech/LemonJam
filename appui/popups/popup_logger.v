module popups

import gg
import time

// import std { Color, ByteStack }
import app { Project }
import std.geom2 { Vec2, Rect2 }
import std.log { LogData }
import uilib { UI, ScrollBar }

pub const base_message_height := 40.0

pub struct LogMessage {
	pub mut:
	time             time.Time
	content          LogMessageContent
	format           LogMessageFormat      = .txt
	
	mut:
	is_unfolded      bool
	is_hovered       bool
	format_rects     []Rect2
	format_hovered   int                   = -1
}

pub fn LogMessage.new(content LogMessageContent) LogMessage {
	return LogMessage{
		time: time.now()
		content: content
		format: content.valid_format[0] or { LogMessageFormat.txt }
		is_unfolded: false
	}
}

pub fn (msg LogMessage) get_height(ui UI) f64 {
	if msg.is_unfolded {
		return base_message_height + ui.style.seperator_height + (msg.content.get_body(msg.format).trim_right("\n").count("\n") + 1) * (ui.style.font_size + ui.style.list_gap) + ui.style.padding
	} else {
		return base_message_height
	}
}

pub fn (mut msg LogMessage) draw(pos Vec2, width f64, mut ui UI) {
	padding := ui.style.padding
	fold_arrow_padding := 6.0
	mut x := pos.x + padding * 2.0
	
	// Draw BG
	ui.draw_rect(
		pos,
		Vec2{width, msg.get_height(ui)},
		fill_color: msg.content.get_color(ui).alpha(0.1)
		fill_type: .full
		outline_color: msg.content.get_color(ui)
		radius: ui.style.rounding
		outline: 2.0
		inset: 2.0
	)
	
	// Draw icon
	ui.draw_icon2(
		msg.content.icon,
		Rect2.from_size(pos, Vec2.v(base_message_height)).inset(fold_arrow_padding).offset(Vec2.v(padding)),
		ui.style.color_text
	)
	
	icon_width := base_message_height
	x += icon_width
	// TODO : Draw icons here
	// Use binary search to trim text in custom function in UI struct
	// Make custom scroll-bar UI component
	
	// Draw time
	time_millis := int(msg.time.nanosecond / 1_000_000)
	time_text := msg.time.hhmmss() + "." + "${time_millis:03}"
	time_width := 140.0
	ui.ctx.draw_text(
		int(x), int(pos.y + base_message_height * 0.5),
		time_text,
		color: ui.style.color_text.get_gx()
		size: ui.style.font_size
		family: ui.style.font_mono
		vertical_align: .middle
	)
	x += time_width
	
	// Draw first title
	first_title_width := 160.0
	title := msg.content.get_title(msg.format)
	if title.contains("|") {
		ui.ctx.draw_text(
			int(x), int(pos.y + base_message_height * 0.5),
			title.all_before("|").trim_left(" "),
			color: ui.style.color_text.get_gx()
			size: int(base_message_height) - 12
			family: ui.style.font_regular
			vertical_align: .middle
		)
		// TODO : Trim title, if it's too long
	}
	x += first_title_width
	
	// Draw second title
	title2_trimmed := ui.trim_text(
		title.all_after("|").trim_left(" "),
		width - x - base_message_height - fold_arrow_padding * 2.0,
		font_size: int(base_message_height) - 12
		font_family: ui.style.font_regular
		trim_delimiter: true
	)
	ui.ctx.draw_text(
		int(x), int(pos.y + base_message_height * 0.5),
		title2_trimmed,
		color: ui.style.color_text.get_gx()
		size: int(base_message_height) - 12
		family: ui.style.font_regular
		vertical_align: .middle
	)
	
	// Draw spacers
	// > Icon - Time
	ui.ctx.draw_line(
		f32(pos.x + icon_width), f32(pos.y + padding + 1),
		f32(pos.x + icon_width), f32(pos.y + base_message_height - padding),
		msg.content.get_color(ui).get_gx()
	)
	// > Time - Title 1 Spacer
	ui.ctx.draw_line(
		f32(pos.x + icon_width + time_width), f32(pos.y + padding + 1),
		f32(pos.x + icon_width + time_width), f32(pos.y + base_message_height - padding),
		msg.content.get_color(ui).get_gx()
	)
	// > Title 1 - Title 2 Spacer
	ui.ctx.draw_line(
		f32(pos.x + icon_width + time_width + first_title_width), f32(pos.y + padding + 1),
		f32(pos.x + icon_width + time_width + first_title_width), f32(pos.y + base_message_height - padding),
		msg.content.get_color(ui).get_gx()
	)
	
	// Draw available formats
	mut x2 := pos.x + width - base_message_height - fold_arrow_padding * 2.0 - padding * 2.0
	msg.format_rects.clear()
	for format in msg.content.valid_format {
		is_format_selected := msg.content.valid_format.len == 0 || format == msg.format
		
		ui.ctx.set_text_cfg(
			size: ui.style.font_size
			family: ui.style.font_bold
			align: .right
			vertical_align: .middle
		)
		text_width := ui.ctx.text_width(format.str())
		
		// > Draw Button BG
		bg_rect := Rect2.from_size(
			Vec2{x2 - text_width - padding, pos.y + base_message_height * 0.5 - f64(ui.style.font_size) * 0.5},
			Vec2{text_width + padding * 2.0, f64(ui.style.font_size)}
		)
		ui.draw_rect(
			bg_rect.a,
			bg_rect.size(),
			fill_color: if is_format_selected { msg.content.get_color(ui) } else { msg.content.get_color(ui).alpha(0.5) }
			radius: ui.style.rounding
		)
		msg.format_rects << bg_rect
		
		mut tag_color := ui.style.color_text
		if msg.content.get_color(ui).luminance() > 0.6 { tag_color = tag_color.darken(0.2) }
		if !is_format_selected { tag_color = tag_color.alpha(0.5) }
		ui.ctx.draw_text(
			int(x2 - f64(text_width) * 0.5), int(pos.y + base_message_height * 0.5),
			format.str(),
			color: tag_color.get_gx()
			size: ui.style.font_size
			family: ui.style.font_bold
			align: .center
			vertical_align: .middle
		)
		x2 -= f64(text_width) + padding * 2.0 + ui.style.list_gap
	}
	
	// Draw folding arrow
	ui.draw_icon(
		if msg.is_unfolded { "point-down" } else { "point-right" },
		pos + Vec2{width - base_message_height + fold_arrow_padding, fold_arrow_padding},
		Vec2{base_message_height - fold_arrow_padding * 2.0, base_message_height - fold_arrow_padding * 2.0},
		ui.style.color_text
	)
	
	// Draw folding seperator if unfolded
	if msg.is_unfolded {
		ui.ctx.draw_line(
			f32(pos.x + padding),         f32(pos.y + base_message_height - 1.0),
			f32(pos.x + width - padding), f32(pos.y + base_message_height - 1.0),
			msg.content.get_color(ui).get_gx()
		)
	}
	
	// Draw content body if unfolded
	if msg.is_unfolded {
		body := msg.content.get_body(msg.format)
		mut y := pos.y + base_message_height + padding
		for line in body.split("\n") {
			ui.ctx.draw_text(
				int(x), int(y),
				line,
				color: ui.style.color_text.get_gx()
				size: ui.style.font_size
				family: ui.style.font_mono
			)
			
			y += ui.style.font_size + ui.style.list_gap
		}
	}
}



@[heap]
pub struct LoggerPopup {
	pub mut:
	from            Vec2
	size            Vec2
	project         Project
	
	messages        []LogMessage         = [
		/*
		LogMessage.new(LogMessageDebug{data: "Hello World"}),
		LogMessage.new(LogMessageError{data: "This is a test error : This is the place, where the error occured : This is the source of the error"}),
		LogMessage.new(LogMessageTCP_IN{action: u32(1), data: [u8(72), u8(101), u8(108), u8(108), u8(111), u8(32), u8(87), u8(111), u8(114), u8(108), u8(100), u8(33)] }),
		*/
	]
	
	pub:
	header_height  f64                   = 24.0
	
	mut:
	scroll_y        f64
	scroll_bar      ScrollBar
}

pub fn LoggerPopup.new(ui UI, from Vec2, size Vec2, mut project Project) &LoggerPopup {
	mut logger := &LoggerPopup{
		from: from
		size: size
		project: project
		scroll_bar: ScrollBar{}
	}
	// Fill current message list with existing messages
	for entry in project.log.entries {
		logger.messages << LogMessage.from_log_data(entry)
	}
	
	// Connect hook to future log messages
	project.log.on_new_entry = fn [mut logger] (entry LogData) {
		logger.messages << LogMessage.from_log_data(entry)
	}
	
	
	return logger
}

pub fn (mut popup LoggerPopup) draw(mut ui UI) {
	// Draw body
	ui.draw_rect(
		popup.from,
		popup.size,
		fill_color: ui.style.color_panel
		radius: ui.style.rounding
	)
	
	// Resize scroll bar
	scroll_bar_width := 6.0
	popup.scroll_bar.from = popup.from + Vec2{popup.size.x, popup.header_height} + Vec2{-ui.style.padding, ui.style.padding} - Vec2{scroll_bar_width, 0.0}
	popup.scroll_bar.size = Vec2{scroll_bar_width, popup.size.y - ui.style.padding * 2.0 - popup.header_height}
	popup.scroll_bar.scroll_area = Rect2{
		popup.from + Vec2{0.0, popup.header_height},
		popup.from + popup.size
	}
	
	// Draw title and close button
	padding := ui.style.padding
	ui.ctx.draw_text(
		int(popup.from.x + padding), int(popup.from.y + padding),
		"Network Traffic Logger",
		color: ui.style.color_text.alpha(0.5).get_gx()
		size: ui.style.font_size
		family: ui.style.font_regular
	)
	
	ui.draw_icon(
		"close",
		popup.from + Vec2{popup.size.x - popup.header_height, 0.0},
		Vec2.v(popup.header_height),
		ui.style.color_text.alpha(0.5)
	)
	
	ui.ctx.draw_line(
		f32(popup.from.x), f32(popup.from.y + popup.header_height),
		f32(popup.from.x + popup.size.x), f32(popup.from.y + popup.header_height),
		ui.style.color_grey.get_gx()
	)
	
	// Draw elements
	// > Push clipping plane
	clipping_plane := Rect2{
		a: popup.from + Vec2{padding, popup.header_height + ui.style.list_gap},
		b: Vec2{popup.scroll_bar.from.x - padding, popup.scroll_bar.from.y + popup.scroll_bar.size.y}
	}
	ui.push_scissor(clipping_plane)
	
	// > Draw element
	x := popup.from.x + padding
	width := popup.size.x - padding * 2.0 - (scroll_bar_width + padding)
	mut y := popup.from.y + popup.header_height + ui.style.list_gap - popup.scroll_bar.offset
	mut total_height := 0.0
	
	for mut element in popup.messages {
		height := element.get_height(ui) + ui.style.list_gap
		if popup.scroll_bar.is_in_range(y, height) {
			element.draw(Vec2{x, y}, width, mut ui)
		}
		y += height
		total_height += height
		
		if element.is_hovered {
			ui.cursor = .pointing_hand
		}
	}
	
	ui.pop_scissor()
	
	// Update and draw scroll bar
	popup.scroll_bar.max_value = f64_max(total_height - ui.style.list_gap, 0.0)
	popup.scroll_bar.range = popup.scroll_bar.size.y
	popup.scroll_bar.draw(mut ui)
}

pub fn (mut popup LoggerPopup) event(mut ui UI, event &gg.Event) ! {
	// Close popup
	popup_rect := Rect2.from_size(popup.from, popup.size)
	if !popup_rect.is_point_inside(ui.mpos) && event.typ == .mouse_down && event.mouse_button == .left {
		popup.close(mut ui)
	}
	
	// TODO : Make close button functional
	
	// Control scrolling
	popup.scroll_bar.event(mut ui, event)!
	
	// Control log messages
	padding := ui.style.padding
	x := popup.from.x + padding
	width := popup.size.x - padding * 2.0 - (popup.scroll_bar.size.x + padding)
	mut y := popup.from.y + popup.header_height + ui.style.list_gap - popup.scroll_bar.offset
	
	for mut msg in popup.messages {
		msg_rect := Rect2.from_size(Vec2{x, y}, Vec2{width, msg.get_height(ui)})
		is_inside_box := msg_rect.is_point_inside(ui.mpos)
		msg.is_hovered = is_inside_box
		
		
		// Allow select of different formats
		msg.format_hovered = -1
		for i, _ in msg.content.valid_format {
			format_rect := msg.format_rects[i] or { continue }
			if format_rect.is_point_inside(ui.mpos) {
				msg.format_hovered = i
			}
		}
		
		// > Fold / Unfold message
		if event.typ == .mouse_down && event.mouse_button == .left && is_inside_box {
			if msg.format_hovered == -1 {
				msg.is_unfolded = !msg.is_unfolded
				return
			} else {
				msg.format = msg.content.valid_format[msg.format_hovered] or { LogMessageFormat.txt }
			}
		}
		
		y += msg.get_height(ui) + ui.style.list_gap
	}
}

pub fn (mut popup LoggerPopup) close(mut ui UI) {
	idx := ui.popups.index(popup)
	if idx != -1 {
		ui.popups.delete(idx)
	}
}
