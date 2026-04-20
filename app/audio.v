module app

import audio.objs { Pattern, Sound, Instrument }

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
					layers << instrument.read_pcm_frames([note], time, frame_count)
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
		layers << instrument.read_pcm_frames([note], time, frame_count)
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

// Plays a preview set of pcm frames over everythin, directly to the output, avioding the audio node graph
pub fn (mut project Project) play_preview_pcm_frames(frames []f64) {
	// TODO : This
}

