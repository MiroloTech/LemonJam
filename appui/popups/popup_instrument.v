module popups

import gg

import std.geom2 { Vec2, Rect2 }
import uilib { UI }
import audio.objs { Instrument }

@[heap]
pub struct InstrumentPopup {
	pub mut:
	from             Vec2
	size             Vec2
	
	instrument       &Instrument
}

pub fn InstrumentPopup.new(from Vec2, size Vec2, mut instrument Instrument) InstrumentPopup {
	return InstrumentPopup{
		from: from
		size: size
		instrument: mut instrument
	}
}


pub fn (mut popup InstrumentPopup) draw(mut ui UI) {
	// Draw body
	ui.draw_rect(
		popup.from,
		popup.size,
		fill_color: ui.style.color_panel
		radius: ui.style.rounding
	)
	
	// Create scissor rect
	ui.push_scissor(Rect2.from_size(popup.from, popup.size))
	
	// Draw instrument
	popup.instrument.from = popup.from
	popup.instrument.size = popup.size
	popup.instrument.draw()
	
	ui.pop_scissor()
}

pub fn (mut popup InstrumentPopup) event(mut ui UI, event &gg.Event) ! {
	// Close instrument on escape
	if event.typ == .key_down && event.key_code == .escape {
		popup.close(mut ui)
		return
	}
	
	// Manage events in instrument
	popup.instrument.event(event)
}

pub fn (mut popup InstrumentPopup) close(mut ui UI) {
	idx := ui.popups.index(popup)
	if idx != -1 {
		ui.popups.delete(idx)
	}
}
