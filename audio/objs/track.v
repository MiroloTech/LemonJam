module objs

import log

import std { Color }
import mirrorlib { NID }

pub enum TrackType {
	pattern
	sound
	animation
}

pub fn TrackType.from_str(str string) !TrackType {
	return match str.to_lower() {
		"pattern" { .pattern }
		"sound" { .sound }
		"animation" { .animation }
		else { error("${str} is an invalid track type") }
	}
}

pub fn (typ TrackType) matches_element_type(obj TrackElementType) bool {
	return (typ == .pattern && obj is Pattern)  ||  (typ == .sound && obj is Sound)
}

pub type TrackElementType = Pattern | Sound

@[heap]
pub struct Track {
	pub mut:
	nid              &NID
	title            string
	typ              TrackType
	elements         []&TrackElement
	colors           map[voidptr]Color
}

@[heap]
pub struct TrackElement {
	pub mut:
	obj           &TrackElementType
	from          f64
	len           f64
}


pub fn (mut track Track) add_element(obj &TrackElementType, from f64, len f64) {
	if track.typ.matches_element_type(obj) {
		element := &TrackElement{obj: obj, from: from, len: len}
		track.colors[element] = Color.hex("#b594ff") // TODO : Set this through the save file
		track.elements << element
	} else {
		log.error("Can't add object of type ${obj.type_name()} to a track with expected type ${track.typ}")
		return
	}
}
