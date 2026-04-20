module app

import audio.objs { Instrument, Pattern, Effect, Note, Track, TrackType }
import std { Color, ByteStack }
import mirrorlib { NID, NIDType, Packet, Server, Conn, Session }
import uilib { UI }
import std.log { Log }

@[heap]
pub struct Project {
	pub mut:
	name                        string
	session                     &Session                = unsafe { nil }
	user_name                   string                  = "Jason"
	
	sample_rate                 u32                     = 44100
	channels                    u32                     = 1
	
	instruments                 []&Instrument
	effects                     []&Effect
	patterns                    []&Pattern
	tracks                      []&Track
	
	log                         &Log                    = &Log{}
	
	// Hooks
	ui                          UI
	
	// TODO : Use custom Signal Data Type here and cary over the .typ of the data as attribute
	on_net_pattern_created      []fn (pattern &Pattern)
	on_net_pattern_updated      []fn (pattern &Pattern)
	on_net_pattern_deleted      []fn (pattern &Pattern)
	on_net_note_created         []fn (pattern &Note)
	on_net_note_updated         []fn (pattern &Note)
	on_net_note_deleted         []fn (pattern &Note)
}



// ===== EDITOR CONTROLS =====
// Creates a new pattern and mirrors that in the seesion
pub fn (mut project Project) new_pattern(name string, color Color) &Pattern {
	// Create pattern instance
	mut pattern := &Pattern{
		name: name
		color: color
		notes: []
		nid: unsafe { nil }
	}
	pattern.nid = project.new_nid(.pattern, pattern)
	project.patterns << pattern
	
	// Create pattern within session
	project.net_create_pattern(pattern)
	
	return pattern
}

pub fn (mut project Project) delete_pattern(pattern &Pattern) {
	// TODO
}

// Creates a new instrument, parses the json-data and mirrors that in the session
pub fn (mut project Project) new_instrument_from_dl_path(dl_path string) !&Instrument {
	// Create instrument instance with empty NID
	mut instrument := Instrument.new_from_dl_path(dl_path) or {
		return error("Failed to create new Instrument instance : ${err}")
	}
	instrument.load(project.make_contexts(["render_context"])) or {
		return error("Failed to create new instrument : ${err}")
	}
	instrument.nid = project.new_nid(.instrument, instrument)
	project.instruments << instrument
	println("New instrument created in project")
	
	return instrument
}

// Creats a new instrument from given save data
// Creates a new instrument, parses the json-data and mirrors that in the session
pub fn (mut project Project) new_instrument_from_save_data(instrument_file string, save_data string) !&Instrument {
	// TODO : This
	return unsafe { nil }
}

pub fn (mut project Project) new_track(title string, typ TrackType) !&Track {
	mut track := &Track{
		title: title
		nid: unsafe { nil }
	}
	track.nid = project.new_nid(.track, track)
	project.tracks << track
	return track
}


// NOTES
pub fn (mut project Project) new_note_simple(from f64, len f64, id int, color Color, mut pattern Pattern, instrument &Instrument) &Note {
	mut note := &Note{
		nid: unsafe { nil }
		from: from
		len: len
		id: id
		color: color
	}
	note.nid = project.new_nid(.note, note)
	pattern.notes << note
	pattern.instruments[note] = instrument
	
	project.net_create_note(pattern, note)
	
	return note
}

pub fn (mut project Project) update_note(note &Note) {
	project.net_update_note(note)
}

pub fn (mut project Project) delete_note(mut pattern Pattern, note &Note) {
	idx := pattern.notes.index(note)
	if idx != -1 {
		pattern.notes.delete(idx)
		pattern.instruments.delete(note)
	} else {
		project.log.failed("Failed to delete Note on client side : Note seems to already be non-existant")
	}
	project.net_delete_note(pattern, note)
}


// WTF is this for, I forgot?!
pub fn (mut project Project) update_ui_from_save_file(mut ui UI) {
	for pattern in project.patterns {
		ui.call_hook("add-to-pattern-list", pattern) or {  }
	}
}


// ===== UTILLITY =====

pub fn get_app_version() string {
	vmod := @VMOD_FILE
	return vmod.find_between("version: '", "'")
}


pub fn (mut project Project) get_pattern_by_nid(nid u64) !&Pattern {
	for mut pattern in project.patterns {
		if pattern.nid == unsafe { nil } { continue }
		if pattern.nid.id == nid {
			return pattern
		}
	}
	return error("No Pattern with given nid '${nid}' exists.")
}

pub fn (mut project Project) get_instrument_by_nid(nid u64) !&Instrument {
	for mut instrument in project.instruments {
		if instrument.nid == unsafe { nil } { continue }
		if instrument.nid.id == nid {
			return instrument
		}
	}
	return error("No Instrument with given nid '${nid}' exists.")
}

pub fn (mut project Project) get_note_by_nid(nid u64) !&Note {
	for mut pattern in project.patterns {
		if pattern.nid == unsafe { nil } { continue }
		for mut note in pattern.notes {
			if note.nid == unsafe { nil } { continue }
			if note.nid.id == nid {
				return note
			}
		}
	}
	return error("No Note with given nid '${nid}' exists.")
}
