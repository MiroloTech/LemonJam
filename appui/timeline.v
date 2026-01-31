module appui

import gg

import std { Color }
import std.geom2 { Vec2 }
import uilib { UI, LineEdit }

import app { Project }
import audio.objs { Track, Pattern, Sound }

@[heap]
pub struct Timeline {
	pub mut:
	from                    Vec2
	size                    Vec2
	
	// UI
	header_height           f64                            = 60.0
	track_head_width        f64                            = 180.0
	
	scroll                  Vec2
	scaling                 Vec2                           = Vec2{40.0, 80.0}               // <px_per_beat, track_height>
	folder_height           f64                            = 25.0
	min_note_range          int                            = 8
	note_edge_spacing       f64                            = 10.0
	
	// Timline Elements
	timeline_elements       []TimelineElement
}

pub type TimelineElement = TrackUI | TrackFolder

@[heap]
pub struct TrackFolder {
	pub mut:
	title                   string
	unfolded                bool                           = true
}

@[heap]
pub struct TrackUI {
	pub mut:
	track                   &Track
	title_edit              LineEdit
	collapsed               bool
}




// ========== TIMELINE IMPLEMENTATION ==========

pub fn (mut timeline Timeline) draw(mut ui UI) {
	ui.push_scissor(a: timeline.from, b: timeline.from + timeline.size)
	
	timeline.draw_header(mut ui)
	timeline.draw_tracks(mut ui)
	
	ui.pop_scissor()
}

pub fn (mut timeline Timeline) event(mut ui UI, event &gg.Event) ! {
	
}

pub fn (timeline Timeline) draw_caret(mut ui UI) {
	
}


// ========== TRACKS IMPLEMENTATION ==========

pub fn (mut timeline Timeline) draw_tracks(mut ui UI) {
	mut y := timeline.header_height + ui.style.padding
	for mut element in timeline.timeline_elements {
		from := timeline.from + Vec2{ui.style.padding, y}
		if element is TrackUI {
			timeline.draw_track(mut ui, from, mut element as TrackUI)
			y += timeline.scaling.y + ui.style.padding
		} else {
			timeline.draw_track_folder(mut ui, from, element as TrackFolder)
			y += timeline.folder_height + ui.style.padding
		}
	}
}



pub fn (timeline Timeline) draw_track(mut ui UI, from Vec2, mut track TrackUI) {
	track_height := timeline.scaling.y
	
	// Dra Track BG
	ui.draw_rect(
		from,
		Vec2{timeline.size.x, track_height},
		
		fill_color: ui.style.color_panel.alpha(0.5)
		fill_type: .double
		
		radius: ui.style.rounding
		radius_tr: 0.0
		radius_br: 0.0
	)
	
	// Draw Track Head
	ui.draw_rect(
		from,
		Vec2{timeline.track_head_width - ui.style.padding, track_height},
		radius: ui.style.rounding
		fill_color: ui.style.color_panel
		radius_tr: 0.0
		radius_br: 0.0
	)
	
	// Draw Track Title
	track.title_edit.from = from + Vec2.v(ui.style.padding)
	track.title_edit.size = Vec2{timeline.track_head_width - ui.style.padding * 3.0, f64(ui.style.font_size) + 2.0}
	track.title_edit.draw(mut ui)
	
	// Draw Track Elements
	for element in track.track.elements {
		// > Draw base BG
		element_from := from + Vec2{timeline.track_head_width, 0.0} + Vec2{element.from * timeline.scaling.x, 0.0}
		element_size := Vec2{element.len * timeline.scaling.x, track_height}
		element_color := if element.obj is Pattern {
			element.obj.color
		} else {
			Color.hex("#0000ff")
		} // track.track.colors[element] or { ui.style.color_error }
		
		ui.draw_rect(
			element_from,
			element_size,
			
			fill_color: element_color.alpha(0.5)
			outline_color: element_color
			
			outline: 2.0
			inset: 1.0
			radius: ui.style.rounding
		)
		
		// > Draw preview
		if element.obj is Pattern {
			// >> Collect note range
			mut min_note := -1
			mut max_note := 0
			mut len := 0.0
			for note in element.obj.notes {
				if note.id < min_note || min_note == -1 {
					min_note = note.id
				}
				if note.id > max_note {
					max_note = note.id
				}
				if note.from + note.len > len {
					len = note.from + note.len
				}
			}
			
			if max_note - min_note < timeline.min_note_range {
				min_note -= timeline.min_note_range / 2
				max_note += timeline.min_note_range / 2
			}
			len /= element_size.x
			
			// >> Draw notes
			for note in element.obj.notes {
				height := element_size.y - timeline.note_edge_spacing * 2.0
				y := ((note.id - max_note) * height) / (min_note - max_note) + timeline.note_edge_spacing
				note_from := element_from + Vec2{note.from / len, y}
				note_size := Vec2{note.len / len, f64_max((max_note - min_note) / height, 4.0)}
				ui.draw_rect(
					note_from,
					note_size,
					
					fill_color: element_color
					radius: ui.style.rounding
				)
			}
		} else if element.obj is Sound {
			// TODO : this
		}
	}
}

pub fn (timeline Timeline) draw_track_folder(mut ui UI, from Vec2, folder &TrackFolder) {
	
}



// ========== HEADER ==========

pub fn (mut timeline Timeline) draw_header(mut ui UI) {
	// Draw vertical split lines
	ui.ctx.draw_line(
		f32(timeline.from.x),                   f32(timeline.from.y + timeline.header_height * 0.5),
		f32(timeline.from.x + timeline.size.x), f32(timeline.from.y + timeline.header_height * 0.5),
		ui.style.color_panel.get_gx()
	)
	
	ui.ctx.draw_line(
		f32(timeline.from.x),                   f32(timeline.from.y + timeline.header_height),
		f32(timeline.from.x + timeline.size.x), f32(timeline.from.y + timeline.header_height),
		ui.style.color_panel.get_gx()
	)
	
	// Draw pattern selector
	ui.ctx.draw_line(
		f32(timeline.from.x + timeline.track_head_width), f32(timeline.from.y + timeline.header_height * 0.5),
		f32(timeline.from.x + timeline.track_head_width), f32(timeline.from.y + timeline.header_height),
		ui.style.color_panel.get_gx()
	)
}

pub fn (mut timeline Timeline) draw_time_bar(mut ui UI) {
	
}


// ========== LOADING ==========

pub fn (mut timeline Timeline) reload(ui UI, project &Project) ! {
	for track in project.tracks {
		// TODO : Implement track folders in project loading
		track_ui := &TrackUI{
			track: track
			title_edit: LineEdit{
				placeholder: "Track Title"
				text: track.title
				underline_color: ui.style.color_panel
			}
		}
		timeline.timeline_elements << track_ui
	}
}


// ========== UTIL ==========
