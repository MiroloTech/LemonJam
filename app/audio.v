module app

import audio.objs { Pattern, Sound, Instrument }
import audio.engine { AudioDevice }

pub fn (mut project Project) get_global_pcm_frames(time f64, frame_count u32) []f64 {
	mut layers := [][]f64{}
	// TODO : Implement this through the node system & Optimize heavily
	for track in project.tracks {
		for element in track.elements {
			if element.obj is &Pattern {
				pattern := element.get_obj[Pattern]()
				for note in pattern.notes {
					mut instrument := pattern.instruments[note] or {
						println("Failed to render following note due to it not having a linked instrument (note will be ignored) : ${note}")
						continue
					}
					layers << instrument.read_pcm_frames([note], time, frame_count, project.sample_rate, project.channels, project.bpm)
				}
			}
		}
	}
	return delayer_frames(layers, frame_count, 0.0)
}

pub fn (mut project Project) get_pattern_pcm_frames(pattern &Pattern, time f64, frame_count u32, sample_rate u32, channels u32) []f64 {
	mut layers := [][]f64{}
	// TODO : Implement this through the node system & Optimize heavily
	for note in pattern.notes {
		mut instrument := pattern.instruments[note] or {
			println("Failed to render following note due to it not having a linked instrument (note will be ignored) : ${note}")
			continue
		}
		if instrument == unsafe { nil } {
			println("ERROR : Instrument of note is nil : ${note}")
			continue
		}
		layers << instrument.read_pcm_frames([note], time, frame_count, sample_rate, channels, project.bpm)
		// TODO : Fix the read_pcm_frames function only returning a flat line
		// TODO : Fix time being very small and broken
	}
	return delayer_frames(layers, frame_count, time)
}

// Mixes all layers together
pub fn delayer_frames(layers [][]f64, frame_count u32, t f64) []f64 {
	// TODO : Optimize this drastically
	mut frames := []f64{len: int(frame_count), init: 0.0}
	for layer in layers {
		for i, v in layer {
			if i == frame_count { break }
			frames[i] += v
		}
	}
	return frames
}

pub fn (project &Project) get_active_instrument() &Instrument {
	if project.instruments.len == 0 {
		eprintln("No active instrument found!")
		return unsafe { nil } // TODO : Make this return an error
	}
	return project.instruments[project.instruments.len - 1]
}


// ===== PLAYBACK =====

struct Playback {
	pub mut:
	device                      &AudioDevice            = unsafe { nil }
	time                        f64
	last_time_step              f64
	playing                     bool
	
	preview_pattern             ?&Pattern
}

pub fn (mut project Project) set_playback_target_pattern(pattern ?&Pattern) {
	project.playback.preview_pattern = pattern
}


// Creates and initializes the main playback device to use when previewing
pub fn (mut project Project) ready_playback() ! {
	mut device := AudioDevice{
		wave_callback: fn [mut project] (frame_count u32, sample_rate u32, channels u32) []f64 {
			
			// Update base values, which are needed to act on the next pcm frame
			sample_count := frame_count / channels
			project.playback.last_time_step = f64(sample_count) / f64(sample_rate)
			if project.playback.playing {
				project.playback.time += project.playback.last_time_step
			}
			
			// Get frames to play in current frame
			if project.playback.playing {
				return project.read_pcm_frames(project.playback.time, frame_count, sample_rate, channels)
			}
			return []f64{len: int(frame_count), init: 0.0}
		}
	}
	project.playback = Playback{device: &device}
	project.playback.device.init()!
}


// Sets the is-playing status of the playback
pub fn (mut project Project) set_playing(is_playing bool) {
	project.playback.playing = is_playing
}

// Simple preview time setter. If play preview is set to true, a small preview section of the audio is played
pub fn (mut project Project) seek_playback_time(beat_time f64) {
	project.playback.time = beat_time / f64(project.bpm / 60.0)
}

// Returns the current playback time varibale in real time
pub fn (project Project) get_playback_time() f64 {
	return project.playback.time
}

// Returns the current playback time variable in beat time
pub fn (project Project) get_playback_beat_time() f64 {
	return project.playback.time * f64(project.bpm / 60.0)
}


// Plays a preview set of pcm frames over everythin, directly to the output, avioding the audio node graph (this is a callback for the playback device, set by `project.ready_playback`)
pub fn (mut project Project) read_pcm_frames(time f64, frame_count u32, sample_rate u32, channels u32) []f64 {
	// TODO : Filter by playback masking
	if project.playback.preview_pattern != none {
		return project.get_pattern_pcm_frames(project.playback.preview_pattern, time, frame_count, sample_rate, channels)
	}
	return project.get_global_pcm_frames(time, frame_count)
}

