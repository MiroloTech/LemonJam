module objs

import mirrorlib { NID }
import std { Color }

@[heap]
pub struct Pattern {
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

