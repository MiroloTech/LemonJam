module objs

import std.log

import std { Color }
import mirrorlib { NID }

@[heap]
pub interface TrackObject {
	mut:
	nid           &NID
	name          string
	color         Color
}

@[heap]
pub struct Track {
	pub mut:
	nid              &NID
	title            string
	elements         []&TrackElement
	
	colors           map[voidptr]Color
}

@[heap]
pub struct TrackElement {
	pub mut:
	obj           &TrackObject
	from          f64
	len           f64
}


pub fn (mut track Track) add_element(obj &TrackObject, from f64, len f64) {
	if !isnil(obj) {
		element := &TrackElement{obj: obj, from: from, len: len}
		track.colors[element] = Color.hex("#b594ff") // TODO : Set this through the save file
		track.elements << element
	} else {
		log.failed("Can't add object of type nil to a track")
		return
	}
}

pub fn (element TrackElement) get_obj[T]() &T {
	return unsafe { &T(element.obj) }
}
