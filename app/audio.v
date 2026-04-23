module app

import audio.objs { Pattern, Sound, Instrument }
import audio.engine { AudioDevice }

pub fn (mut project Project) get_global_pcm_frames(time f64, frame_count u32) []f64 {
	mut layers := [][]f64{}
	// TODO : Implement this through the node system & Optimize heavily
	for track in project.tracks {
		for element in track.elements {
			if element.obj is Pattern {
				for note in element.obj.notes {
					mut instrument := element.obj.instruments[note] or {
						println("Failed to render following note due to it not having a linked instrument (note will be ignored) : ${note}")
						continue
					}
					layers << instrument.read_pcm_frames([note], time, frame_count, project.sample_rate, project.channels, project.bpm)
				}
			} else if element.obj is Sound {
				// TODO : This
			}
		}
	}
	return delayer_frames(layers, frame_count)
}

pub fn (mut project Project) get_pattern_pcm_frames(pattern &Pattern, time f64, frame_count u32) []f64 {
	mut layers := [][]f64{}
	// TODO : Implement this through the node system & Optimize heavily
	for note in pattern.notes {
		mut instrument := pattern.instruments[note] or {
			println("Failed to render following note due to it not having a linked instrument (note will be ignored) : ${note}")
			continue
		}
		layers << instrument.read_pcm_frames([note], time, frame_count, project.sample_rate, project.channels, project.bpm)
		// TODO : Fix the read_pcm_frames function only returning a flat line
		// TODO : Fix time being very small and broken
	}
	return delayer_frames(layers, frame_count)
}

// Mixes all layers together
pub fn delayer_frames(layers [][]f64, frame_count u32) []f64 {
	// TODO : Optimize this drastically
	mut frames := []f64{len: int(frame_count), init: 0.0}
	for layer in layers {
		for i, v in layer {
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
	preview_beats               f64
	preview_target_samples      int
	seek_preview_time           f64                     = 0.2
	
	preview_pattern             ?&Pattern
}

pub fn (mut project Project) set_playback_target_pattern(pattern ?&Pattern) {
	project.playback.preview_pattern = pattern
}


// Creates and initializes the main playback device to use when previewing
pub fn (mut project Project) ready_playback() ! {
	device := &AudioDevice{
		wave_callback: fn [mut project] (frame_count u32, sample_rate u32, channels u32) []f64 {
			// TODO : Fix GC error by MAYBEEEEE locking the project when modifying it's values
			// (may cause concurrency issues when trying to offset preview_beets in seek_playback while offseting them in this callback fucntion)
			sample_count := frame_count / channels
			frames_beats := f64(frame_count) / f64(sample_rate) * f64(project.bpm / 60.0)
			if project.playback.preview_target_samples > 0 {
				project.playback.preview_target_samples = int_max(int(project.playback.preview_target_samples) - int(sample_count), 0)
			}
			if project.playback.preview_target_samples == 0 {
				return []f64{len: int(frame_count), init: 0.0}
			}
			project.playback.preview_beats = f64(project.playback.preview_beats) + frames_beats
			frames := project.read_pcm_frames(project.playback.preview_beats, frame_count, sample_rate, channels)
			return frames
		}
	}
	project.playback = Playback{device: device}
	project.playback.device.init()!
}

// Simple preview time setter. If play preview is set to true, a small preview section of the audio is played
pub fn (mut project Project) seek_playback(beats f64, play_preview bool) {
	project.playback.preview_beats = beats
	if play_preview {
		project.playback.preview_target_samples = int(f64(project.sample_rate) * project.playback.seek_preview_time) // Plays a half of a second of preview audio
	}
}

// Plays a preview set of pcm frames over everythin, directly to the output, avioding the audio node graph (this is a callback for the playback device, set by `project.ready_playback`)
pub fn (mut project Project) read_pcm_frames(time f64, frame_count u32, _sample_rate u32, _channels u32) []f64 {
	// TODO : Filter by playback masking
	if project.playback.preview_pattern != none {
		return project.get_pattern_pcm_frames(project.playback.preview_pattern, time, frame_count)
	}
	return project.get_global_pcm_frames(time, frame_count)
}

