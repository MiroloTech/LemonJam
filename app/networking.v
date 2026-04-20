module app

import audio.objs { Instrument, Pattern, Effect, Note, Track, TrackType }
import std { Color, ByteStack }
import mirrorlib { NID, NIDType, Packet, Server, Conn, Session }

import std.log { Log }


// ===== NID CONTROLS =====

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



// ===== MIRROR CONTROLS =====

// Creates a new pattern mirror in the seesion
pub fn (mut project Project) net_create_pattern(pattern &Pattern) {
	// Create pattern within session
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(pattern.nid.id)
		data.push_u8(u8(NIDType.pattern))
		data.push_string(pattern.name)
		data.push_color(pattern.color)
		project.session.send_packet(Packet{action: mirrorlib.action_element_create, data: data})
	}
}


// Creates a new note mirror in the session
pub fn (mut project Project) net_create_note(pattern &Pattern, note &Note) {
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
}


// Updates the note mirror
pub fn (mut project Project) net_update_note(note &Note) {
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

// Deletes a note mirror
pub fn (mut project Project) net_delete_note(pattern &Pattern, note &Note) {
	if project.session != unsafe { nil } {
		mut data := ByteStack{}
		data.push_u64(note.nid.id)
		data.push_u8(u8(NIDType.note))
		data.push_u64(pattern.nid.id)
		project.session.send_packet(Packet{action: mirrorlib.action_element_delete, data: data})
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



// ========== SESSION RESPONSES ==========

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
				
				// TODO : Experiment with $... something something, which pre-defines the skelleton of the interpretation of this section of code in a .txt file
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

