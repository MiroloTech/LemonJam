module objs

import os
import dl
import gg
import x.json2 as json

// import std.project
import std.geom2 { Vec2 }
import mirrorlib { NID, Packet }

type FNInstrumentLoad = fn (contexts map[string]voidptr) voidptr
type FNInstrumentDraw = fn (ptr voidptr, window_from Vec2, window_size Vec2)
type FNInstrumentEvent = fn (ptr voidptr, event &gg.Event)
type FNInstrumentPCMFrame = fn (ptr voidptr, notes []Note, time f64, frame_count u32, sample_rate u32, channels u32, bpm f64) []f64 

@[heap]
pub struct Instrument {
	pub mut:
	nid                    &NID
	
	name                   string
	creator                string
	description            string
	json_path              string
	
	system                 voidptr                   = unsafe { nil }
	
	fn_draw                FNInstrumentDraw          = unsafe { nil }
	fn_event               FNInstrumentEvent         = unsafe { nil }
	fn_pcm_frames          FNInstrumentPCMFrame      = unsafe { nil }
	dl_handle              voidptr
	
	// TODO : Note in .json file, which contexts is required to use the instrument
	
	from                   Vec2
	size                   Vec2
}

// Creates an unloaded instrument from the given path to the matching dynamic library
pub fn Instrument.new_from_dl_path(path string) !&Instrument {
	// Get matching json file
	if os.is_dir(path) {
		return error("Given path to instrument must be a dynamic library file or fitting .json instrument file.")
	}
	
	if !path.ends_with(".json") && !path.ends_with(dl.get_shared_library_extension()) {
		return error("Invalid extension in file of path found '${path}' : Make sure, the path is either a .json file or a mathich .dll file ")
	}
	
	json_path := os.join_path(path.all_before_last("\\").all_before_last("/"), os.file_name(path).all_before_last(".")) + ".json"
	json_raw := os.read_file(json_path) or {
		return error("Failed to open and read .json file at path '${json_path}' : ${err}")
	}
	
	// Read out, if file is instrument, title and icon of instrument and proper dl file path
	json_decoded := json.decode[json.Any](json_raw) or {
		return error("Failed to decode .json file at '${json_path}' for instrument creation : ${err}")
	}
	json_data := json_decoded.as_map_of_strings()
	
	// Create proper unloaded instrument
	instrument := &Instrument{
		nid:             unsafe { nil }
		
		name:            json_data["name"] or { "_unnamed" }
		creator:         json_data["creator"] or {"_unknown"}
		description:     json_data["description"] or { "" }
		json_path:       json_path
		
		system:          unsafe { nil }
		dl_handle:       unsafe { nil }
	}
	
	return instrument
}

pub fn (mut instrument Instrument) load(contexts map[string]voidptr) ! {
	// Get system-specific path to dynamic library file
	mut dl_path := os.join_path(instrument.json_path.all_before_last("\\").all_before_last("/"), os.file_name(instrument.json_path).all_before_last("."))
	dl_path += dl.get_shared_library_extension()
	
	// TODO : Implement custom error here, which specificallyf states, that the file is not os-compatible
	
	// Open dl file
	handle := dl.open_opt(dl_path, dl.rtld_global) or {
		return error("Failed to load instrument dynamic library file at ${dl_path} : ${err}")
	}
	
	// Get load symbol in dl handle
	load_fn := FNInstrumentLoad(dl.sym_opt(handle, "load_dl_instance") or {
		return error("Failed to find 'load' function in dl file. Make sure, the .dl file has an 'load' function, which returns a reference to the main Instrument struct. : ${err}")
	})
	
	// Get draw and event symbold and attatch them to the instrument instance
	fn_draw := FNInstrumentDraw(dl.sym_opt(handle, "draw") or {
		return error("Failed to find 'draw' function in dl file. Make sure, the .dl file has a 'draw' function. : ${err}")
	})
	fn_event := FNInstrumentEvent(dl.sym_opt(handle, "event") or {
		return error("Failed to find 'event' function in dl file. Make sure, the .dl file has a 'event' function. : ${err}")
	})
	
	fn_pcm_frames := FNInstrumentPCMFrame(dl.sym_opt(handle, "pcm_frames") or {
		return error("Failed to find 'pcm_frames' function in dl file. Make sure, the .dl file has a 'pcm_frames' function. : ${err}")
	})
	
	// Call load function and place resulting instrument system in instrument
	// instrument_system := &InstrumentSystem(load_fn())
	instrument.system = load_fn(contexts)
	instrument.fn_draw = fn_draw
	instrument.fn_event = fn_event
	instrument.fn_pcm_frames = fn_pcm_frames
	
	// Add reference to handle to close later
	instrument.dl_handle = handle
}

pub fn (mut instrument Instrument) draw() {
	instrument.fn_draw(instrument.system, instrument.from, instrument.size)
}


pub fn (mut instrument Instrument) event(event &gg.Event) {
	instrument.fn_event(instrument.system, event)
}

pub fn (mut instrument Instrument) read_pcm_frames(notes []&Note, time f64, frame_count u32, sample_rate u32, channels u32, bpm f64) []f64 {
	frames := instrument.fn_pcm_frames(instrument.system, notes.simplify(), time, frame_count, sample_rate, channels, bpm)
	return frames
}


pub fn (mut instrument Instrument) cleanup() {
	if instrument.dl_handle != unsafe { nil } {
		// dl.close(instrument.dl_handle) // IDK why, but this crashes the app a lot of the times...
		instrument.dl_handle = unsafe { nil }
	}
}


