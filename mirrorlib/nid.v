module mirrorlib

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
	id      u64
	typ     NIDType
	ptr     voidptr
	locked  bool             = true
}

// Returns the data for a packet to mirror across different devices (Note: Mirrors full instance, but not sub-instances (Pattern mirrors Pattern, but not the Notes in Pattern))
pub fn (nid NID) get_data[T]() []u8 {
	// TODO : This
}

