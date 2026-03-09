module mirrorlib

// import audio.objs { Instrument, Pattern, Effect, Note, Track, TrackType }

pub enum NIDType {
	other
	note
	pattern
	instrument
	effect
	track
}

@[heap]
pub struct NID {
	pub mut:
	id      u64
	typ     NIDType
	ptr     voidptr
	locked  bool            = true
}

// Returns the data for a packet to mirror across different devices (Note: Mirrors full instance, but not sub-instances (Pattern mirrors Pattern, but not the Notes in Pattern))
pub fn (nid NID) get_data[T]() []u8 {
	match nid.typ {
		.pattern {
			/*
			pattern := unsafe { &Pattern(nid.ptr) }
			mut data := []u8{}
			*/
			// data << 
			return []u8{}
		}
		else { return []u8{} }
	}
}
