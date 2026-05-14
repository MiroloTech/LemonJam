module uilib

import std { Color }
import std.geom2 { Vec2 }
import audio.objs { TrackElement, Pattern, Sound }

const min_note_preview_range = 8


@[heap]
pub struct TrackElementUI {
	pub mut:
	element          &TrackElement
	
	color_override   ?Color
	is_selected      bool
	is_collapsed     bool
}


pub fn TrackElementUI.from_element_arr(elements []&TrackElement) []&TrackElementUI {
	mut element_uis := []&TrackElementUI{}
	for element in elements {
		element_uis << &TrackElementUI{
			element: element
		}
	}
	return element_uis
}
pub fn (element_ui TrackElementUI) draw(mut ui UI, from Vec2, size Vec2) {
	// Draw BG
	ui.draw_rect(
		from,
		size,
		
		fill_color: element_ui.get_color().alpha(0.5)
		outline_color: element_ui.get_color()
		
		outline: 2.0
		inset: 1.0
		radius: ui.style.rounding
	)
	
	if element_ui.is_collapsed { return }
	
	// Draw name of object
	ui.draw_rect(
		from,
		Vec2{size.x, 10.0},
		
		fill_color: element_ui.get_color()
		
		inset: 1.0
		radius: ui.style.rounding
		radius_bl: 0.0
		radius_br: 0.0
	)
	
	ui.ctx.draw_text(
		int(from.x + ui.style.padding * 0.5),
		int(from.y + 5.0),
		element_ui.element.obj.name,
		
		size: 12
		color: ui.style.color_grey.get_gx()
		align: .left
		vertical_align: .middle
		family: ui.style.font_mono
	)
	
	// Draw element preview
	if element_ui.element.obj is &Pattern {
		pattern := &Pattern(element_ui.element.obj)
		
		// > Collect note range
		mut min_note := -1
		mut max_note := 0
		mut len := 0.0
		for note in pattern.notes {
			if note.id < min_note || min_note == -1 {
				min_note = note.id
			}
			if note.id > max_note {
				max_note = note.id
			}
			if note.from + note.len > len {
				len = note.from + note.len
			}
		}
		
		if max_note - min_note < min_note_preview_range {
			min_note -= min_note_preview_range / 2
			max_note += min_note_preview_range / 2
		}
		len /= size.x
		
		// > Draw notes
		note_edge_spacing := 10.0
		for note in pattern.notes {
			height := size.y - note_edge_spacing * 2.0
			y := ((note.id - max_note) * height) / (min_note - max_note) + note_edge_spacing
			note_from := from + Vec2{note.from / len, y}
			note_size := Vec2{note.len / len, f64_max((max_note - min_note) / height, 4.0)}
			ui.draw_rect(
				note_from,
				note_size,
				
				fill_color: element_ui.get_color()
				radius: ui.style.rounding
			)
		}
	} else if element_ui.element.obj is &Sound {
		// TODO : This
	}
}

pub fn (element_ui TrackElementUI) draw_outline(mut ui UI, from Vec2, size Vec2) {
	ui.draw_rect(
		from,
		size,
		
		radius: ui.style.rounding
		fill_color: Color.hex("#00000000")
		
		outline: 3.0
		outline_color: ui.style.color_text
	)
}


fn (element_ui TrackElementUI) get_color() Color {
	return element_ui.color_override or { element_ui.element.obj.color }
}


