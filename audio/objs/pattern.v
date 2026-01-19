module objs

import mirrorlib { NID }
import std { Color }

@[heap]
pub struct Pattern {
	pub mut:
	nid          &NID
	name         string
	notes        []&Note
	colors       map[voidptr]Color
	instruments  map[voidptr]&Instrument
}

