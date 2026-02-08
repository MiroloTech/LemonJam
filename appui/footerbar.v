module appui

import gg
import sokol.sapp

import std.geom2 { Vec2 }
import uilib { UI, ActionList, Action, FooterHook }

/*
The Footer (or footer bar) shows possible actions or action descriptions, you can perform within the editor context.
TODO : Add support for differnet colors and keyboard key display
*/


@[heap]
pub struct Footer {
	pub mut:
	height          f64                 = 20.0
	text            string
	reset_event_typ sapp.EventType      = .mouse_down
}

pub fn (footer Footer) draw(mut ui UI) {
	// Draw BG
	from := ui.bottom_left() - Vec2{0, footer.height}
	size := Vec2{ui.get_window_size().x, footer.height}
	ui.ctx.draw_rect_filled(
		f32(from.x), f32(from.y),
		f32(size.x), f32(size.y),
		ui.style.color_bg.brighten(0.025).get_gx()
	)
	
	// Draw text
	text_pos := ui.bottom_left() + Vec2{ui.style.padding * 2.0, -footer.height * 0.5}
	
	ui.ctx.draw_text(
		int(text_pos.x), int(text_pos.y),
		footer.text,
		color: ui.style.color_grey.get_gx()
		size: ui.style.font_size
		align: .left
		vertical_align: .middle
		family: ui.style.font_mono
	)
}


pub fn (mut footer Footer) event(mut ui UI, event &gg.Event) {
	if event.typ == footer.reset_event_typ {
		footer.text = ""
	}
}


// Shows a message in the footer bar, which gets reset once an event of given type is registered
pub fn (mut footer Footer) display_until(msg string, event_typ sapp.EventType) {
	footer.text = msg
	footer.reset_event_typ = event_typ
}

pub fn (mut footer Footer) display_until_hook(data_src voidptr) {
	data := unsafe { &FooterHook(data_src) }
	footer.display_until(data.msg, data.event_typ)
}
