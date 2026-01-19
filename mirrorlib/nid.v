module mirrorlib

pub enum NIDType {
	other
	note
	pattern
	instrument
	effect
}

@[heap]
pub struct NID {
	id      u64
	typ     NIDType
	locked  bool             = true
}


// TODO : Compare ngrok with a custom relay server
