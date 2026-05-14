module appui

import gg
import math { ceil, mod, floor }

// import std { Color }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, LineEdit, TrackElementUI, Playhead }

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
	collapsed_track_height  f64                            = 28.0
	playhead                Playhead                       = Playhead{}
	panning                 bool
	
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
	element_uis             []&TrackElementUI
}


// ========== TIMELINE IMPLEMENTATION ==========

pub fn (mut timeline Timeline) draw(mut ui UI) {
	ui.push_scissor(a: timeline.from, b: timeline.from + timeline.size)
	
	timeline.draw_header(mut ui)
	timeline.draw_bar_lines(mut ui)
	timeline.draw_tracks(mut ui)
	timeline.draw_playhead(mut ui)
	
	ui.pop_scissor()
}

pub fn (mut timeline Timeline) event(mut ui UI, event &gg.Event) ! {
	timeline.playhead.event(event)!
	timeline.control_pan(event, ui.style.pan_speed)!
}

pub fn (mut timeline Timeline) draw_playhead(mut ui UI) {
	timeline.playhead.scroll_x = timeline.scroll.x
	timeline.playhead.px_per_beat = timeline.scaling.x
	playhead_offset := Vec2{timeline.track_head_width, timeline.header_height}
	timeline.playhead.from = timeline.from + playhead_offset
	timeline.playhead.size = timeline.size - playhead_offset
	timeline.playhead.draw(mut ui)
}

pub fn (timeline Timeline) draw_bar_lines(mut ui UI) {
	ui.push_scissor(a: timeline.from + Vec2{timeline.track_head_width - 1, timeline.header_height * 0.75}, b: timeline.from + timeline.size)
	
	// Draw beat & bar lines
	lines := int(ceil(timeline.size.x / timeline.scaling.x)) + 1
	for l in 0..lines {
		beat := int(floor(f64(l + timeline.scroll.x / timeline.scaling.x)))
		line_pos := timeline.track_head_width + f64(l) * timeline.scaling.x - mod(timeline.scroll.x, timeline.scaling.x)
		over_header_extension := if beat % 4 == 0 { 0.25 } else { 0.0 }
		ui.ctx.draw_line(
			f32(timeline.from.x + line_pos), f32(timeline.from.y + timeline.header_height * (1.0 - over_header_extension)),
			f32(timeline.from.x + line_pos), f32(timeline.from.y + timeline.size.y),
			if beat % 4 == 0 { ui.style.color_grey.alpha(0.8).get_gx() } else { ui.style.color_grey.alpha(0.2).get_gx() }
		)
		
		// Draw bar counter
		if beat % 4 == 0 {
			ui.ctx.draw_text(
				int(timeline.from.x + line_pos + 2.0), int(timeline.from.y + timeline.header_height * (1.0 - over_header_extension)),
				"${beat / 4}",
				color: ui.style.color_grey.get_gx()
				size: ui.style.font_size
				align: .left
				vertical_align: .top
				family: ui.style.font_mono
			)
		}
	}
	
	ui.pop_scissor()
}

pub fn (mut timeline Timeline) control_pan(event &gg.Event, pan_speed f64) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	is_inside_window := Rect2.from_size(timeline.from, timeline.size).is_point_inside(mpos)
	
	if event.typ == .mouse_move && timeline.panning {
		timeline.scroll.x -= event.mouse_dx * pan_speed
		timeline.scroll.y -= event.mouse_dy * pan_speed
		if timeline.scroll.x < 0.0 { timeline.scroll.x = 0.0 }
		if timeline.scroll.y < 0.0 { timeline.scroll.y = 0.0 }
	}
	
	if event.typ == .mouse_up || event.mouse_button == .invalid {
		timeline.panning = false
		return uilib.surpress_event()
	}
	if event.typ == .mouse_down && event.mouse_button == .middle && is_inside_window {
		timeline.panning = true
		return uilib.surpress_event()
	}
	
	if timeline.panning {
		return uilib.surpress_event()
	}
}


// ========== TRACKS IMPLEMENTATION ==========

pub fn (mut timeline Timeline) draw_tracks(mut ui UI) {
	ui.push_scissor(a: timeline.from + Vec2{0, timeline.header_height}, b: timeline.from + timeline.size)
	mut y := timeline.header_height + ui.style.padding - timeline.scroll.y
	
	for mut element in timeline.timeline_elements {
		from := timeline.from + Vec2{ui.style.padding, y}
		if mut element is TrackUI {
			timeline.draw_track(mut ui, from, mut element as TrackUI)
			y += if element.collapsed { timeline.collapsed_track_height } else { timeline.scaling.y } + ui.style.padding
		} else {
			timeline.draw_track_folder(mut ui, from, element as TrackFolder)
			y += timeline.folder_height + ui.style.padding
		}
	}
	
	ui.pop_scissor()
}

pub fn (timeline Timeline) draw_track(mut ui UI, from Vec2, mut track TrackUI) {
	track_height := if track.collapsed { timeline.collapsed_track_height } else { timeline.scaling.y }
	
	// Draw Track BG
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
	
	// Draw Collapse Icon
	collapse_icon_size := 18.0
	collapse_icon_pos := from + Vec2{timeline.track_head_width - collapse_icon_size - ui.style.padding * 2.0, ui.style.padding}
	if track.collapsed {
		ui.draw_icon(
			"point-right",
			collapse_icon_pos,
			Vec2.v(collapse_icon_size),
			ui.style.color_text
		)
	} else {
		ui.draw_icon(
			"point-down",
			collapse_icon_pos,
			Vec2.v(collapse_icon_size),
			ui.style.color_text
		)
	}
	
	// Draw Track Elements
	ui.push_scissor(a: timeline.from + Vec2{timeline.track_head_width - 1, timeline.header_height}, b: timeline.from + timeline.size)
	
	for mut element_ui in track.element_uis {
		// > Draw base BG
		element_from := from + Vec2{timeline.track_head_width - ui.style.padding, 0.0} + Vec2{element_ui.element.from * timeline.scaling.x, 0.0} - Vec2{timeline.scroll.x, 0.0}
		element_size := Vec2{element_ui.element.len * timeline.scaling.x, track_height}
		element_ui.is_collapsed = track.collapsed
		element_ui.draw(mut ui, element_from, element_size)
	}
	
	ui.pop_scissor()
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
		mut track_ui := &TrackUI{
			track: track
			title_edit: LineEdit{
				placeholder: "Track Title"
				text: track.title
				underline_color: ui.style.color_panel
			}
		}
		track_ui.element_uis << TrackElementUI.from_element_arr(track.elements)
		timeline.timeline_elements << track_ui
	}
}


// ========== UTIL ==========
