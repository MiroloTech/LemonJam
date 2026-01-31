module popups

import gg

import std { Color }
import app { Project }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, Event, Button, LineEdit }

@[heap]
pub struct NewPatternPopup {
	pub mut:
	from            Vec2
	size            Vec2
	
	pattern_name    string
	project         &Project
	visible         bool
	
	mut:
	btn_cancel      Button
	btn_create      Button
	line_edit_name  LineEdit
}

pub fn NewPatternPopup.new(ui UI, from Vec2, size Vec2, project &Project) NewPatternPopup {
	padding := ui.style.strong_padding
	return NewPatternPopup{
		from: from
		size: size
		project: project
		
		btn_cancel: Button{
			from: from + Vec2{padding * 0.5 + size.x * 0.5, size.y - 24.0 - padding}
			size: Vec2{size.x * 0.5 - padding * 1.5, 24.0}
			title: "Cancel"
			typ: .dark
		}
		btn_create: Button{
			from: from + Vec2{padding, size.y - 24.0 - padding}
			size: Vec2{size.x * 0.5 - padding * 1.5, 24.0}
			title: "Create"
		}
		line_edit_name: LineEdit{
			from: from + Vec2{padding, padding * 2.0 + ui.style.font_size_title}
			size: Vec2{size.x - padding * 2.0, 24.0}
			// text: "Unnamed"
			placeholder: "Name your new Pattern..."
		}
	}
}

pub fn (mut popup NewPatternPopup) draw(mut ui UI) {
	// Draw body
	ui.draw_rect(
		popup.from,
		popup.size,
		fill_color: ui.style.color_panel
		radius: ui.style.rounding
	)
	
	// Draw titel
	padding := ui.style.strong_padding
	ui.ctx.draw_text(
		int(popup.from.x + padding), int(popup.from.y + padding),
		"Create new Pattern",
		color: ui.style.color_text.get_gx()
		size: ui.style.font_size_title
		family: ui.style.font_bold
		bold: true
	)
	
	// Draw buttons
	popup.btn_cancel.draw(mut ui)
	popup.btn_create.draw(mut ui)
	
	// Draw line edit
	popup.line_edit_name.draw(mut ui)
}

pub fn (mut popup NewPatternPopup) event(mut ui UI, event &gg.Event) ! {
	// Create popup on submit
	if event.typ == .key_down && event.key_code == .enter && popup.line_edit_name.is_focused {
		popup.create_pattern(mut ui)!
		popup.close(mut ui)
	}
	
	// Update components
	popup.btn_cancel.event(mut ui, event)
	popup.btn_create.event(mut ui, event)
	popup.line_edit_name.event(mut ui, event)
	
	// Close popup on escape key press
	if event.typ == .key_down && event.key_code == .escape {
		popup.close(mut ui)
	}
	
	// Properly create pattern & update ui
	if popup.btn_create.is_pressed {
		popup.create_pattern(mut ui)!
	}
	
	// Close popup on any action
	if (popup.btn_cancel.is_pressed || popup.btn_create.is_pressed) && !popup.line_edit_name.is_focused {
		popup.close(mut ui)
	}
}

pub fn (mut popup NewPatternPopup) create_pattern(mut ui UI) ! {
	pattern_name := popup.line_edit_name.text
	if pattern_name == "" {
		ui.call_hook("toast-error", "Invalid pattern name".str) or {  }
		return uilib.surpress_event()
	}
	if popup.project == unsafe { nil } {
		ui.call_hook("toast-error", "No Project loaded".str) or {  }
		return uilib.surpress_event()
	}
	pattern := popup.project.new_pattern(pattern_name, Color.hex("00ff00"))
	// TODO : Add color selector popup inside popup
	ui.call_hook("add-to-pattern-list", pattern) or {  }
	ui.call_hook("toast-info", "New Pattern created : ${pattern_name}".str) or {  }
}

pub fn (mut popup NewPatternPopup) close(mut ui UI) {
	idx := ui.popups.index(popup)
	if idx != -1 {
		ui.popups.delete(idx)
	}
}
