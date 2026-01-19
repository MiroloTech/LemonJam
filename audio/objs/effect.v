module objs

import mirrorlib { NID }

@[heap]
pub struct Effect {
	pub mut:
	nid          &NID
	name         string
	icon         string
	effect       EffectSystem
}

pub interface EffectSystem {
	sample_rate     u32
	channels        u32
	
	mut:
	apply_to_pcm_frames(frames []f64, time f64) []f64
}
