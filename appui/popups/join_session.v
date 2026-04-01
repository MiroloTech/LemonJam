module popups

import gg

import app { Project }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, Event, Button, LineEdit }

@[heap]
pub struct JoinSessionPopup {
	pub mut:
	from               Vec2
	size               Vec2
	
	pattern_name       string
	project            &Project
	visible            bool
	
	mut:
	btn_cancel         Button
	btn_create         Button
	session_code_edit  LineEdit
}

pub fn JoinSessionPopup.new(ui UI, from Vec2, size Vec2, project &Project) JoinSessionPopup {
	padding := ui.style.strong_padding
	return JoinSessionPopup{
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
			title: "Join"
		}
		session_code_edit: LineEdit{
			from: from + Vec2{padding, padding * 2.0 + ui.style.font_size_title}
			size: Vec2{size.x - padding * 2.0, 24.0}
			placeholder: "Session Code..."
		}
	}
}

pub fn (mut popup JoinSessionPopup) draw(mut ui UI) {
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
		"Join Session",
		color: ui.style.color_text.get_gx()
		size: ui.style.font_size_title
		family: ui.style.font_bold
		bold: true
	)
	
	// Draw buttons
	popup.btn_cancel.draw(mut ui)
	popup.btn_create.draw(mut ui)
	
	// Draw line edit
	popup.session_code_edit.draw(mut ui)
}

pub fn (mut popup JoinSessionPopup) event(mut ui UI, event &gg.Event) ! {
	// Create popup on submit
	if event.typ == .key_down && event.key_code == .enter && popup.session_code_edit.is_focused {
		popup.join_session(mut ui)
		popup.close(mut ui)
	}
	
	// Update components
	popup.btn_cancel.event(mut ui, event)
	popup.btn_create.event(mut ui, event)
	popup.session_code_edit.event(mut ui, event)
	
	// Close popup on escape key press
	if event.typ == .key_down && event.key_code == .escape {
		popup.close(mut ui)
	}
	
	// Properly create pattern & update ui
	if popup.btn_create.is_pressed {
		popup.join_session(mut ui)
	}
	
	// Close popup on any action
	if (popup.btn_cancel.is_pressed || popup.btn_create.is_pressed) && !popup.session_code_edit.is_focused {
		popup.close(mut ui)
	}
}

pub fn (mut popup JoinSessionPopup) join_session(mut ui UI) {
	code := popup.session_code_edit.text
	println("Code : ${code}")
	popup.project.join_session(code) or {
		// log.failed("Failed to join session : ${err}")
		popup.close(mut ui)
	}
}

pub fn (mut popup JoinSessionPopup) close(mut ui UI) {
	idx := ui.popups.index(popup)
	if idx != -1 {
		ui.popups.delete(idx)
	}
}
