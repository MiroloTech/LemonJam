module objs

import mirrorlib { NID }

import log

@[heap]
pub struct Instrument {
	pub mut:
	nid          &NID
	name         string
	file         string
	icon         string
	instrument   InstrumentSystem      = TempInstrumentSystem{}
}

pub fn (mut instrument Instrument) load() ! {
	instrument.instrument = TempInstrumentSystem{}
	// TODO : Load this through .dll or .vst
}

pub interface InstrumentSystem {
	save_data() string
	
	mut:
	sample_rate    u32
	channels       u32
	
	read_pcm_frames(notes []&Note, time f64, frame_count u32) []f64
	load_from_data(data string)
}




pub struct TempInstrumentSystem{
	pub mut:
	sample_rate    u32     = u32(44100)
	channels       u32     = u32(2)
}

pub fn (_ TempInstrumentSystem) save_data() string {
	return ""
}

pub fn (mut _ TempInstrumentSystem) read_pcm_frames(note []&Note, time f64, frame_count u32) []f64 {
	mut temp_frames := []f64{}
	for _ in 0..frame_count {
		temp_frames << 0.0
	}
	return temp_frames
}

pub fn (mut _ TempInstrumentSystem) load_from_data(data string) {
	log.info("Data loaded for temporary instrument : ${data}")
}
