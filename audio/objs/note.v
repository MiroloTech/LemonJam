module objs

/*
import rand

import std.ease { EaseFn }
import std.anim { AnimProperty }
import audio { note2freq }

@[heap]
pub struct Note {
	pub mut:
	from          f64
	len           f64
	
	id            AnimProperty[f64] = AnimProperty[f64]{}
	volume        AnimProperty[f64] = AnimProperty[f64]{from: 1.0, to: 1.0}
	pan           AnimProperty[f64] = AnimProperty[f64]{from: 0.0, to: 0.0}
	phase         f64           = 0.0
}


// Creates and retursn a new note with basic stats
pub fn Note.new(from f64, len f64, id f64, volume f64) Note {
	return Note{
		from: from
		len: len
		id: AnimProperty{from: id, to: id}
		volume: AnimProperty{from: volume, to: volume}
		pan: AnimProperty{from: 0.0, to: 0.0} // TODO : Make this a Vec3
		phase: rand.f64()
	}
}

// Creates and retursn a new note with animatable stats
pub fn Note.new_animated(from f64, len f64, ida f64, idb f64, idc EaseFn, volumea f64, volumeb f64, volumec EaseFn, pana f64, panb f64, panc EaseFn) Note {
	return Note{
		from:    from
		len:      len
		id:      AnimProperty{from: ida,      to: idb,      easing: idc}
		volume:  AnimProperty{from: volumea,  to: volumeb,  easing: volumec}
		pan:     AnimProperty{from: pana,     to: panb,     easing: panc}
		phase: rand.f64()
	}
}


// Returns 'true' if the time falls in the range of the Note
pub fn (note Note) is_active(time f64) bool {
	return time >= note.from && time < note.from + note.len
}


// Returns the time fration between 0.0 and 1.0 in the Note
fn (note Note) get_time_fract(time f64) f64 {
	return (time - note.from) / note.len
}


// Returns the matching note id
pub fn (note Note) get_noteid(time f64) int {
	f := note.get_time_fract(time)
	return int(note.id.get(f))
}

// Returns the matching note including leaning
pub fn (note Note) get_note(time f64) f64 {
	f := note.get_time_fract(time)
	return note.id.get(f)
}

// Returns the matching note frequency
pub fn (note Note) get_freq(time f64) f64 {
	n := note.get_note(time)
	return note2freq(n)
}

// Reutnrs the matching frequency note to the notes id plus offset
pub fn (note Note) get_offset_freq(time f64, off f64) f64 {
	n := note.get_note(time) + off
	return note2freq(n)
}

// Returns the matching note volume
pub fn (note Note) get_volume(time f64) f64 {
	f := note.get_time_fract(time)
	return note.volume.get(f)
}

// Returns the matching note volume
pub fn (note Note) get_pan(time f64) f64 {
	f := note.get_time_fract(time)
	return note.pan.get(f)
}

*/


import std.ease { EaseFn }
import std.geom3 { Vec3 }

@[heap]
pub struct Note {
	pub mut:
	from        f64
	len         f64
	
	id         int
	id2        ?int
	volume     f64          = 1.0
	volume2    ?f64
	pan        Vec3
	pan2       ?Vec3
	
	easing     ?EaseFn
}


// Returns true, if any of the properties in the note is curved ( a.k.a has specific start- and end value for any property )
pub fn (note Note) is_curved() bool {
	return note.id2 != none || note.volume2 != none || note.pan2 != none
}




