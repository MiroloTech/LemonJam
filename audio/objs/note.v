module objs

import mirrorlib { NID }
import std.ease { EaseFn }
import std.geom3 { Vec3 }

@[heap]
pub struct Note {
	pub mut:
	from        f64
	len         f64
	
	nid        &NID
	
	id         int
	id2        ?int
	volume     f64          = 1.0
	volume2    ?f64
	pan        Vec3
	pan2       ?Vec3
	
	easing     ?EaseFn
}

pub const tags := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


// Returns true, if any of the properties in the note is curved ( a.k.a has specific start- and end value for any property )
pub fn (note Note) is_curved() bool {
	return note.id2 != none || note.volume2 != none || note.pan2 != none
}


// Returns a proper note struct from the given tag, commonly found in the save files
pub fn Note.from_data_tag(data_tag string, nid &NID) Note {
	data := data_tag.split(",")
	if data.len == 0 {
		return Note{nid: nid}
	}
	
	key := tags.index(if data[0].contains("#") { data[0].substr(0, 2) } else { data[0].substr(0, 1) })
	octave := data[0].replace(tags[key], "").int()
	id := octave * 12 + key
	
	range := (data[1] or { "0.0-4.0" }).split("-")
	from := range[0].f64()
	len := (range[1] or { "4.0" }).f64()
	
	
	return Note{
		from: from
		len: len
		id: id
		nid: nid
	}
}



