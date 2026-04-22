import gg

import app.context { DlRenderContext }
import std { Color }
import std.geom2 { Vec2, Rect2 }
import audio
import audio.objs { Note }
import mirrorlib { Packet }


@[heap]
pub struct Aurora {
	pub:
	// Contexts
	render_ctx            DlRenderContext             @[required]
	
	pub mut:
	sample_rate           u32
	channels              u32
	
	net_send_packet       fn (packet Packet)          = fn (packet Packet) {  }
	
	from                  Vec2
	size                  Vec2
	
	// Instrument
	last_pcm_beat         f64                         = -1.0
	playing_notes         []Note                      = []Note{}
	preview_time          f64                         = 0.05
	preview_sample_rate   u32                         = 4000
}

@[export: 'load_dl_instance']
pub fn load_dl_instance(contexts map[string]voidptr) &Aurora {
	return &Aurora{
		render_ctx: *(unsafe { &DlRenderContext(contexts["render_context"] or { nil }) })
	}
}

// ===== SAVE / LOAD =====

/*
@[export: 'save_data']
pub fn (aurora Aurora) save_data() string {
	// Implement code to return proper save data for the instrument here
	return ""
}

@[export: 'load_from_data']
pub fn (mut aurora Aurora) load_from_data(data string) {
	// Implement code to react to loading the instrument from save data here
}
*/


// ===== NETWORKING =====

/*
pub fn (mut aurora Aurora) send_packet(packet Packet) {
	// Implement code to send packet through the network...
	aurora.net_send_packet(packet)
}

pub fn (mut aurora Aurora) net_on_packet(packet Packet) {
	// Implement code to react to a netowrking packet here...
	// Note : This only receives Instrument-specific packets and session join / exit packets
}
*/



// ===== UI =====

@[export: 'draw']
pub fn draw(ptr voidptr, window_from Vec2, window_size Vec2) {
	mut aurora := unsafe { &Aurora(ptr) }
	
	aurora.from = window_from
	aurora.size = window_size
	
	// Get collective wave of all currently-playing notes
	preview_samples := int(f64(aurora.preview_sample_rate) * aurora.preview_time)
	mut samples := []f64{len: preview_samples, init: 0.0}
	for x in 0..preview_samples {
		mut s := 0.0
		for note in aurora.playing_notes {
			freq := audio.note2freq(f64(note.id))
			amp := note.volume
			
			// > Add samples to list of frames
			t := f64(x) / f64(aurora.preview_sample_rate)
			// s += sin(math.tau / (t * freq)) * amp
			s += audio.simple_wave_sin(t, freq, amp)
		}
		samples[x] = s
	}
	
	// Draw audio wave
	mut last_x := aurora.from.x
	mut last_y := samples[0] * aurora.size.y * 0.5 + aurora.from.y + aurora.size.y * 0.5
	
	for i, y in samples {
		if i == 0 { continue }
		
		// > Get current and next sample to make line
		x1 := last_x
		x2 := f64(i) / f64(preview_samples) * aurora.size.x + aurora.from.x
		y1 := last_y
		y2 := y * aurora.size.y * 0.3 + aurora.from.y + aurora.size.y * 0.5
		
		
		// > Draw line between two samples, scaled across window
		aurora.render_ctx.draw_line_with_config(
			Vec2{x1, y1},
			Vec2{x2, y2},
			gg.PenConfig{
				// thickness: f32(4)
				// color: Color.hex("#ffffff").get_gx()
				color: Color.hex("#b2aeff").get_gx()
			}
		)
		
		last_x = x2
		last_y = y2
	}
}

@[export: 'event']
pub fn event(ptr voidptr, event &gg.Event) {
	// mut aurora := unsafe { &Aurora(ptr) }
}



// ===== AUDIO =====
// TODO : Fully rename time to beat to avoid confusion

@[export: 'pcm_frames']
pub fn pcm_frames(ptr voidptr, notes []Note, beat f64, frame_count u32, sample_rate u32, channels u32, bpm f64) []f64 {
	mut aurora := unsafe { &Aurora(ptr) }
	inv_sample_rate := 1.0 / f64(sample_rate)
	
	// Create empty frame array
	if beat != aurora.last_pcm_beat { // > Allow for note stacking, when pcm_frames function is called two times with the same time
		aurora.playing_notes = []
	}
	time := beat / bpm * 60.0
	mut frames := []f64{len: int(frame_count), init: 0.0}
	
	// Get all effected notes
	for note in notes {
		is_time_in_note := note.from <= time && time <= note.from + note.len
		if is_time_in_note {
			aurora.playing_notes << note
			
			freq := audio.note2freq(f64(note.id))
			amp := note.volume * 0.25
			
			// > Add samples to list of frames
			for i in 0..frames.len {
				t := time + f64(i) * inv_sample_rate
				// print("(${(t*1000):.8},")
				frames[i] += audio.simple_wave_sin(t, freq, amp)
				// print("${frame:.3}), ")
			}
		}
	}
	aurora.last_pcm_beat = beat
	
	// Return sample collection
	return frames
}

