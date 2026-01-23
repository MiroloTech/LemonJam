module uilib

import math { floor }

import std.geom2 { Vec2, Rect2 }

pub struct Piano {
    pub mut:
    from                         Vec2
    size                         Vec2
    
    note_count                   int              = 12 * 6 + 1
    spacing                      f64              = 0.0
    offset                       f64              = 0.0
    
    height_white                 f64              = 30.0
    height_black                 f64              = 18.0
	
	note_ratio_border            f64              = 0.35
	note_ratio_black             f64              = 0.35
	note_ratio_white             f64              = 0.3
}


const note_tags := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


// Returns an array of all keys for every note in the given range
pub fn (piano Piano) get_piano_keys() []Rect2 {
	mut y := -piano.offset
	mut keys := []Rect2{}
	
	for i in 0..piano.note_count {
		n := piano.note_count - i - 1
		// > Black keys
		if [1, 3, 6, 8, 10].contains(n % 12) {
			keys << Rect2.from_size(
				piano.from + Vec2{0.0, y - piano.height_black * 0.5},
				Vec2{piano.size.x * 0.7, piano.height_black}
			)
		}
		// > White keys
		else {
			keys << Rect2.from_size(
				piano.from + Vec2{0.0, y},
				Vec2{piano.size.x, piano.height_white}
			)
			y += piano.height_white + piano.spacing
		}
	}
	
	return keys.reverse()
}


pub fn (piano Piano) draw_piano(mut ui UI) {
    // Draw piano
	keys := piano.get_piano_keys()
	
	// > Draw white
	for n, rect in keys {
		if [0, 2, 4, 5, 7, 9, 11].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y - 0.5),
				ui.style.color_note_white.get_gx()
			)
			// > Draw note tags for all white notes, except the C note
			if n % 12 != 0 {
				ui.ctx.draw_text(
					int(rect.b.x - ui.style.padding * 2.0), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
					note_tags[n % 12] or { "--" },
					color: ui.style.color_grey.brighten(0.55).get_gx()
					size: ui.style.font_size
					align: .right
					vertical_align: .middle
					family: ui.style.font_mono
				)
			}
		}
		
		// >> Draw note tag for C note
		if n % 12 == 0 {
			octave := int(floor(f64(n) / 12.0))
			ui.ctx.draw_text(
				int(rect.b.x - ui.style.padding), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
				"C${octave}",
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				family: ui.style.font_mono
			)
		}
	}
	
	// > Draw black
	for n, rect in keys {
		if [1, 3, 6, 8, 10].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_note_black.get_gx()
			)
			ui.ctx.draw_text(
				int(rect.b.x - ui.style.padding), int(rect.a.y + (rect.b.y - rect.a.y) * 0.5),
				note_tags[n % 12] or { "--" },
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .right
				vertical_align: .middle
				family: ui.style.font_mono
			)
		}
	}
}


pub fn (piano Piano) get_piano_rails(from Vec2, size Vec2) []Rect2 {
	mut y := -piano.offset
	mut rails := []Rect2{}
	
	octave_height := piano.height_white * 7.0
	
	for i in 0..piano.note_count {
		n := piano.note_count - i - 1
		is_white := [0, 2, 4, 5, 7, 9, 11].contains(n % 12)
		is_border := [0, 4, 5, 11].contains(n % 12)
		h := if i == 0 {
			piano.height_white + piano.spacing
		} else if is_border {
			piano.note_ratio_border / 4.0 * octave_height + piano.spacing
		} else {
			if is_white {
				piano.note_ratio_white / 3.0 * octave_height + piano.spacing
			} else {
				piano.note_ratio_black / 5.0 * octave_height
			}
		}
		
		rails << Rect2.from_size(from + Vec2{0.0, y}, Vec2{size.x, h})
		
		y += h
	}
	
	return rails.reverse()
}


pub fn (piano Piano) total_piano_height() f64 {
	octaves := int(floor(f64(piano.note_count) / 12.0))
	remaining := piano.note_count % 12
	white_notes := octaves * 7 + [0, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6, 7][remaining] or { 0 }
	return f64(white_notes) * (piano.height_white + piano.spacing)
}

