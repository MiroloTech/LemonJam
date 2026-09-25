module objs

import mirrorlib { NID }
import std { Color }

@[heap]
pub struct Pattern implements TrackObject {
	pub mut:
	nid          &NID
	name         string
	notes        []&Note
	color        Color
	instruments  map[voidptr]&Instrument
}

pub fn (pattern Pattern) get_note_colors() map[voidptr]Color {
	mut colors := map[voidptr]Color{}
	for note in pattern.notes {
		colors[note] = note.color
	}
	return colors
}

// Returns the total length of the pattern by returning maximum note.from + note.len value in beats
pub fn (pattern Pattern) get_total_length() f64 {
	mut x := 0.0
	for note in pattern.notes {
		x = f64_max(x, note.from + note.len)
	}
	return x
}

