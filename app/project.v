module app

import audio.objs { Instrument, Pattern, Effect, Note, Track, TrackType }
import std { Color, ByteStack }
import mirrorlib { NID, NIDType, Packet, Server, Conn, Session }
import uilib { UI, NoteUI }

import semver
import os
import std.log { Log }
import x.json2 as json

@[heap]
pub struct Project {
	pub mut:
	name                        string
	session                     &Session                = unsafe { nil }
	user_name                   string                  = "Jason"
	
	sample_rate                 u32
	channels                    u32
	
	instruments                 []&Instrument
	effects                     []&Effect
	patterns                    []&Pattern
	tracks                      []&Track
	
	log                         &Log                    = &Log{}
	
	// Hooks
	ui_ptr                      voidptr
	
	// TODO : Use custom Signal Data Type here and cary over the .typ of the data as attribute
	on_net_pattern_created      []fn (pattern &Pattern)
	on_net_pattern_updated      []fn (pattern &Pattern)
	on_net_pattern_deleted      []fn (pattern &Pattern)
	on_net_note_created         []fn (pattern &Note)
	on_net_note_updated         []fn (pattern &Note)
	on_net_note_deleted         []fn (pattern &Note)
}

pub fn (project Project) save_to_file(path string) ! {
	// TODO
}

pub fn (mut project Project) load_from_file(path string) ! {
	// LOAD JSON DATA
	text := os.read_file(path) or { return error("Failed to open save file : ${err}") }
	raw_data := json.decode[json.Any](text) or { return error("Failed to load top-most layer of save file : ${err}") }
	data := raw_data.as_map()
	project_data := (data["project"] or { return error("Failed to find project data in file") }).as_map()
	
	// CHECK COMPATIBILITY
	version_str := get_app_version()
	version := semver.from(version_str) or {
		return error("Application is at invalid version : ${version_str}")
	}
	
	file_version_str := project_data["lmnj-version"] or { return error("Failed to find project version in file") }
	file_version := semver.from(version_str) or {
		return error("Project version given is of invalid format : ${file_version_str}")
	}
	
	if file_version < version {
		log.warn("Save file version is less than the current application version")
	}
	
	// LOAD BASIC SETTINGS
	project.sample_rate = (project_data["sample-rate"] or { 44100 }).u32()
	project.channels = (project_data["channels"] or { 2 }).u32()
	
	// LOAD INSTRUMENTS
	instruments := data["instruments"] or { []json.Any{} }
	for instrument_id, raw_instrument_data in instruments.as_array() {
		instrument_data := raw_instrument_data.as_map()
		instrument_file := instrument_data["file"] or { return error("Failed to find file in instrument ${instrument_id}") }
		raw_instrument_user_data := instrument_data["data"] or { "" }
		project.new_instrument(instrument_file.str(), raw_instrument_user_data.str()) or {
			return error("Failed to load instrument with file ${instrument_file.str()} : ${err}")
		}
	}
	
	// LOAD PATTERNS
	patterns := data["patterns"] or { []json.Any{} }
	for raw_pattern_data in patterns.as_array() {
		pattern_data := raw_pattern_data.as_map()
		name_data := (pattern_data["name"] or { "unnamed" }).str()
		color_data := Color.hex((pattern_data["color"] or { "#fff0000" }).str())
		mut pattern := project.new_pattern(name_data, color_data)
		
		// > Parse notes
		raw_notes := pattern_data["notes"] or { return error("Failed to find property 'notes' in save file") }
		notes := raw_notes.as_array()
		for note_data in notes {
			mut note := Note.from_data_tag(note_data.str(), unsafe { nil })
			note.nid = project.new_nid(.note, note)
			pattern.notes << &note
		}
		
		// > Parse note colors
		raw_note_colors := pattern_data["colors"] or { return error("Failed to find property 'notes' in save file") }
		note_colors := raw_note_colors.as_map()
		for color, raw_note_ids in note_colors {
			for note_id in raw_note_ids.as_array() {
				mut note := pattern.notes[note_id.int()] or { continue }
				// pattern.colors[note] = Color.hex(color.str())
				note.color = Color.hex(color.str())
			}
		}
		
		// > Parse note instruments
		// { "0": [0, 1, 2], "1":, [3, 4, 5] }
		raw_instrument_data := pattern_data["instruments"] or { json.Any("") }
		mut notes_covered_by_instrument := []int{len: notes.len, init: index}
		for str_instrument_id, raw_instrument_note_arr in raw_instrument_data.as_map() {
			// 0: [0, 1, 2]
			instrument_id := str_instrument_id.int()
			instrument_raw_notes := raw_instrument_note_arr.as_array()
			instrument := project.instruments[instrument_id] or { continue }
			
			for instrument_raw_note in instrument_raw_notes {
				// 0, 1, 2
				id := instrument_raw_note.int()
				note := pattern.notes[id] or { continue }
				notes_covered_by_instrument.delete(notes_covered_by_instrument.index(id))
				pattern.instruments[note] = instrument
			}
		}
	}
	
	// LOAD TRACKS
	tracks := data["tracks"] or { []json.Any{} }.as_array()
	for raw_track_data in tracks {
		track_data := raw_track_data.as_map()
		track_title := track_data["title"] or { "unnamed" }.str()
		track_type_str := track_data["type"] or { return error("No 'track-type' given in track ${track_title}") }.str()
		track_typ := TrackType.from_str(track_type_str) or { return error("Invalid track type found in track ${track_data} : ${err}") }
		
		mut track := project.new_track(track_title, track_typ) or { return error("Failed to create new track object in project : ${err}") }
		match track_typ {
			.pattern {
				raw_elements := (track_data["elements"] or { break }).as_array()
				for raw_element in raw_elements {
					element_data := raw_element.as_map()
					from := element_data["from"]     or { continue }.f64()
					len := element_data["len"]       or { continue }.f64()
					id := element_data["element-id"] or { continue }.int()
					
					pattern := project.patterns[id]  or { continue }
					track.add_element(pattern, from, len)
				}
			}
			else {  }
		}
		
		// TODO : Implement sounds & animations
		
	}
	
	// TODO : The rest...
}


// Creates a new unique NID instance of given type and mirrors that to every other connected user
pub fn (mut project Project) new_nid(typ NIDType, data_ptr voidptr) &NID {
	if project.session == unsafe { nil } {
		return unsafe { nil }
	}
	
	nid := project.session.get_new_nid() or {
		log.failed("Failed to get new NID from Session Server : ${err}")
		return unsafe { nil }
	}
	mut nid_instance := &NID{
		id: nid
		typ: typ
		ptr: data_ptr
		locked: false
	}
	return nid_instance
}



pub fn (mut project Project) lock_nid(mut nid &NID) {
	// TODO
}

pub fn (mut project Project) unlock_nid(mut nid &NID) {
	// TODO
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
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(pattern.nid.id)
		data.push_u8(u8(NIDType.pattern))
		data.push_string(name)
		data.push_color(color)
		project.session.send_packet(Packet{action: mirrorlib.action_element_create, data: data})
	}
	
	return pattern
}

pub fn (mut project Project) delete_pattern(pattern &Pattern) {
	// TODO
}

// Creates a new pattern, parses the json-data and mirrors that in the session
pub fn (mut project Project) new_instrument(file string, json_data string) !&Instrument {
	mut instrument := &Instrument{
		name: file.all_before_last(".").title()
		nid: unsafe { nil }
	}
	instrument.load() or {
		return error("Failed to create new instrument : ${err}")
	}
	instrument.nid = project.new_nid(.instrument, instrument)
	project.instruments << instrument
	return instrument
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
	
	// Create note in pattern within session
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(note.nid.id)
		data.push_u8(u8(NIDType.note))
		data.push_u64(pattern.nid.id)
		data.push_u64(0) // data.push_u64(instrument.nid.id)
		data.push_int(note.id)
		data.push_f64(note.from)
		data.push_f64(note.len)
		data.push_f64(note.volume)
		data.push_vec3(note.pan)
		data.push_color(note.color)
		project.session.send_packet(Packet{action: mirrorlib.action_element_create, data: data})
	}
	
	return note
}

pub fn (mut project Project) update_note(note &Note) {
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(note.nid.id)
		data.push_u8(u8(NIDType.note))
		data.push_int(note.id)
		data.push_f64(note.from)
		data.push_f64(note.len)
		data.push_f64(note.volume)
		data.push_vec3(note.pan)
		data.push_color(note.color)
		project.session.send_packet(Packet{action: mirrorlib.action_element_update, data: data})
	}
}

pub fn (mut project Project) delete_note(mut pattern Pattern, note &Note) {
	idx := pattern.notes.index(note)
	if idx != -1 {
		pattern.notes.delete(idx)
		pattern.instruments.delete(note)
	} else {
		project.log.failed("Failed to delete Note on client side : Note seems to already be non-existant")
	}
	
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(note.nid.id)
		data.push_u8(u8(NIDType.note))
		data.push_u64(pattern.nid.id)
		project.session.send_packet(Packet{action: mirrorlib.action_element_delete, data: data})
	}
}


// WTF is this for, I forgot?!
pub fn (mut project Project) update_ui_from_save_file(mut ui UI) {
	for pattern in project.patterns {
		ui.call_hook("add-to-pattern-list", pattern) or {  }
	}
}

// ========== SESSION CONTROLS ==========

pub fn (mut project Project) start_session(server Server) ! {
	project.log.info("Starting new session at server '${server.title}' ...")
	
	project.session = Session.new_session(server, mut project.log) or {
		project.log.failed("Failed to start session : ${err}")
		return error("Failed to start Session : ${err}")
	}
	// TODO : Make sure, this freezes until ready or failes before continuing
	project.connect_session()
	println("Session ready!")
}

pub fn (mut project Project) join_session(code string) ! {
	project.log.info("Joining new session with code '${code}' ...")
	project.session = Session.join_session(code, mut project.log) or {
		project.log.failed("Failed to join session : ${err}")
		return error("Failed to join Session : ${err}")
	}
	// TODO : Make sure, this freezes until ready or failes before continuing
	project.connect_session()
	println("Session ready!")
}

// This function connects session packet-hooks to the project instance to allow for proper reactions to events
pub fn (mut project Project) connect_session() {
	if project.session == unsafe { nil } {
		log.failed("Failed to properly connect session hooks to the project : Session not initialized")
		return
	}
	
	project.session.on_packet_create = fn [mut project] (nid_id u64, data []u8) {
		mut bytes := ByteStack(data.clone())
		
		typ := bytes.pop_u8()
		match typ {
			u8(NIDType.pattern) { // Pattern
				// > Fetch data for creating a new pattern
				name := bytes.pop_string()
				color := bytes.pop_color()
				
				// > Create new NID instance
				mut nid := &NID{
					id: nid_id
					typ: .pattern
					ptr: unsafe { nil }
				}
				
				// > Create new Pattern
				mut pattern := &Pattern{
					name: name
					color: color
					notes: []
					nid: nid
				}
				nid.ptr = pattern
				
				// > Add Pattern to project
				// TODO : Make custom append function to check, if object with that NID already exists
				project.patterns << pattern
				
				// > Call hook after pattern is created
				for func in project.on_net_pattern_created {
					func(pattern)
				}
			}
			u8(NIDType.note) { // Note
				// TODO : Add a buffered-packets list to add data[] to if the pattern doesn't exists.
				// Project will attempt to re-parse all buffered packets (from oldest to newest), but pops them after 3 failed attempts
				// > Fetch data for creating a new note
				pattern_nid := bytes.pop_u64()
				instrument_nid := bytes.pop_u64()
				id := bytes.pop_int()
				from := bytes.pop_f64()
				len := bytes.pop_f64()
				volume := bytes.pop_f64()
				pan := bytes.pop_vec3()
				color := bytes.pop_color()
				
				// > Fetch existing pattern and instrument for a proper connection
				mut pattern := project.get_pattern_by_nid(pattern_nid) or {
					project.log.failed("Tried to add a note to a pattern, that doesn't exist (yet) : Pattern NID '${pattern_nid}'.")
					return
				}
				
				mut instrument := project.get_instrument_by_nid(instrument_nid) or {
					project.log.failed("Tried to add a note to a pattern, that doesn't exist (yet) : Instrument NID '${pattern_nid}'.")
					// return
					unsafe { nil }
				} // TODO : Instrument support
				
				// > Create new NID instance
				mut nid := &NID{
					id: nid_id
					typ: .note
					ptr: unsafe { nil }
				}
				
				// > Create new Note
				mut note := &Note{
					nid: nid
					from: from
					len: len
					id: id
					volume: volume
					pan: pan
					color: color
				}
				
				// > Add note to pattern
				pattern.notes << note
				pattern.instruments[note] = instrument
				
				// > Call hook after note is created
				for func in project.on_net_note_created {
					func(note)
				}
			}
			else {  }
		}
	}
	
	project.session.on_packet_update = fn [mut project] (nid_id u64, data []u8) {
		mut bytes := ByteStack(data.clone())
		
		typ := bytes.pop_u8()
		match typ {
			u8(NIDType.note) { // Notes
				id := bytes.pop_int()
				from := bytes.pop_f64()
				len := bytes.pop_f64()
				volume := bytes.pop_f64()
				pan := bytes.pop_vec3()
				color := bytes.pop_color()
				
				// > Create new Note
				mut note := project.get_note_by_nid(nid_id) or {
					project.log.failed("Tried to fetch existing note, that doesn't exist (yet) : Note NID '${nid_id}'.")
					return
				}
				
				note.from = from
				note.len = len
				note.id = id
				note.volume = volume
				note.pan = pan
				note.color = color
				
				// > Call hook after note is created
				for func in project.on_net_note_updated {
					func(note)
				}
			}
			else {  }
		}
	}
	
	project.session.on_packet_delete = fn [mut project] (nid_id u64, data []u8) {
		mut bytes := ByteStack(data.clone())
		
		typ := bytes.pop_u8()
		match typ {
			u8(NIDType.note) { // Notes
				pattern_nid := bytes.pop_u64()
				
				// > Create new Note
				mut note := project.get_note_by_nid(nid_id) or {
					project.log.failed("Tried to fetch existing note, that doesn't exist (yet) : Note NID '${nid_id}'.")
					return
				}
				
				// > Fetch existing pattern for a proper removal
				mut pattern := project.get_pattern_by_nid(pattern_nid) or {
					project.log.failed("Tried to add a note to a pattern, that doesn't exist (yet) : Pattern NID '${pattern_nid}'.")
					return
				}
				
				// > Remove note from pattern, if exists
				idx := pattern.notes.index(note)
				if idx != -1 {
					pattern.notes.delete(idx)
				}
				if pattern.instruments.keys().contains(voidptr(note)) {
					pattern.instruments.delete(note)
				}
				
				// > Call hook after note is created
				for func in project.on_net_note_deleted {
					func(note)
				}
			}
			else {  }
		}
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
