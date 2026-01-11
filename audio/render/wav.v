module render

import audio.objs { Pattern }

import os
import time

pub fn write_wav(path string, patterns []Pattern, sample_rate u32, bit_depth u16, length f64, volume f64) ! {
	// Start timer
	stopwatch := time.now()
	
	// Create file
	if os.is_file(path) {
		os.rm(path) or { return error("Can't remove old .wav audio file : ${err}") }
	}
	
	mut file := os.create(path) or { return error("Can't create a file to save .wav file : ${err}") }
	
	// Values
	channels := 2
	samples := u64(length * sample_rate)
	data_byte_count := samples * u64(bit_depth / 8) * u64(channels)
	
	// Chunks
	// > Header
	file.write_string("RIFF")                                                                        or { return error("WAV File write error : 'RIFF' header") }
	file.write_le[u32](u32(data_byte_count + 44 - 8))                                                or { return error("WAV File write error : file size - 8") }
	file.write_string("WAVE")                                                                        or { return error("WAV File write error : header data") }
	
	// > Format
	file.write_string("fmt ")                                                                        or { return error("WAV File write error : 'fmt' header") }
	file.write_le[u32](u32(16))                                                                      or { return error("WAV File write error : size of format chunk") }
	file.write_le[u16](u16(1))                                                                       or { return error("WAV File write error : sample type ( PCM Integer )") }
	file.write_le[u16](u16(channels))                                                                or { return error("WAV File write error : channels") }
	file.write_le[u32](u32(sample_rate))                                                             or { return error("WAV File write error : sample rater") }
	file.write_le[u32](u32( sample_rate * u64(bit_depth) * u64(channels) / u64(8) ))                 or { return error("WAV File write error : data byte count") }
	file.write_le[u16](u16((bit_depth * channels) / 8))                                              or { return error("WAV File write error : bits per sample for all channels") }
	file.write_le[u16](u16(bit_depth))                                                               or { return error("WAV File write error : bits per sample") }
	
	// > Data
	file.write_string("data")                                                                        or { return error("WAV File write error : 'data' header") }
	file.write_le[u32](u32(data_byte_count))                                                         or { return error("WAV File write error : size of data chunk") }
	
	for s in 0..samples {
		t := f64(s) / f64(sample_rate)
		mut sample := 0.0
		for patt in patterns {
			sample += patt.sample(t)
		}
		
		if s % 1000 == 0 {
			progress := f64(s) / f64(samples) * 100.0
			println("Sample ${s} of ${samples} : ${progress:.1}%")
		}
		
		sample *= volume
		
		// >> Clamp sample
		if sample < -1.0 { sample = -1.0 }
		if sample > 1.0 { sample = 1.0 }
		
		// sample *= 0.00001
		
		// println("${t:.2} : ${sample:.2}")
		
		// TODO : Make this more modular to also work with u24, etc.
		// TODO : Properly implement different channels with paning
		for _ in 0..channels {
			if bit_depth == 8 {
				file.write_le[i8](i8( sample * f64(max_i8) / 2.0 ))                                or { return error("WAV File write error : cant write u8 sample") }
			}
			else if bit_depth == 16 {
				file.write_le[i16](i16( sample * f64(max_i16) / 2.0 ))                             or { return error("WAV File write error : cant write u16 sample") }
			}
			else if bit_depth == 32 {
				file.write_le[int](int( sample * f64(max_int) / 2.0 ))                             or { return error("WAV File write error : cant write u32 sample") }
			}
			else if bit_depth == 64 {
				file.write_le[i64](i64( sample * f64(max_int) / 2.0 ))                             or { return error("WAV File write error : cant write u64 sample") }
			} else { return error("WAV File write error : unsupported bit depth : ${bit_depth}") }
		}
	}
	
	// Finish writing
	file.close()
	
	// Print elapsed time
	elapsed := time.since(stopwatch).seconds()
	println("Rendered in ${elapsed} seconds")
}
