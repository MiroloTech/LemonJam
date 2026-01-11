module audio

import math { sin, abs, fmod }

pub type FnSimpleWave = fn (x f64, freq f64, amp f64) f64

// Simple music sin wave
pub fn simple_wave_sin(x f64, freq f64, amp f64) f64 {
	return sin(x * math.tau * freq) * amp
}
// Simple music square wave
pub fn simple_wave_sqr(x f64, freq f64, amp f64) f64 {
	return if sin(x * math.tau * freq) * amp > 0.0 { amp } else { -amp }
}
// Simple music saw wave
pub fn simple_wave_saw(x f64, freq f64, amp f64) f64 {
	return fmod(x * freq, 1.0) * 2.0 * amp - amp
}
// Simple music triangle wave
pub fn simple_wave_tri(x f64, freq f64, amp f64) f64 {
	p := 1.0 / freq
	return (4.0*amp) / p * abs[f64](fmod(x - (p/4.0), p) - p/2.0) - amp
}

// TODO : Add noise wave
