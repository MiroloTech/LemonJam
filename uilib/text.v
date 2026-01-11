module uilib

import gg

import std.geom2 { Vec2 }

pub type HorizontalAlign = gg.HorizontalAlign
pub type VerticalAlign = gg.VerticalAlign

pub struct Text {
	pub mut:
	from       Vec2
	size       Vec2
	text       string
	
	mono       bool
	bold       bool
	italic     bool
	
	halign     HorizontalAlign
	valign     VerticalAlign
}


pub fn (mut text Text) draw(mut ui UI) {
	// TODO : Multiline support
	// > Determine text position
	mut p := text.from
	if text.halign == .center {
		p.x += text.size.x * 0.5
	}
	else if text.halign == .right {
		p.x += text.size.x
	}
	
	if text.valign == .middle || text.valign == .baseline {
		p.y += text.size.y * 0.5
	}
	else if text.valign == .bottom {
		p.y += text.size.y
	}
	
	// > Determine font
	mut font := ui.style.font_regular
	if text.mono && text.italic {
		font = ui.style.font_bold_italic
	} else if text.bold {
		font = ui.style.font_bold
	} else if text.italic {
		font = ui.style.font_italic
	}
	if text.mono {
		font = ui.style.font_mono
	}
	
	// > Draw text
	ui.ctx.draw_text(
		int(p.x), int(p.y),
		text.text,
		color: ui.style.color_text.get_gx()
		size: ui.style.font_size
		align: text.halign
		vertical_align: text.valign
		max_width: int(text.size.x)
		family: font
	)
}
