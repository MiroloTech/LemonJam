module app

import audio.objs { Instrument, Pattern, Effect, Note, Track, TrackType }
import std { Color, ByteStack }
import std.log { Log }

import semver
import os
import x.json2 as json


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
		project.new_instrument_from_save_data(instrument_file.str(), raw_instrument_user_data.str()) or {
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
