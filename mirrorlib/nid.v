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
