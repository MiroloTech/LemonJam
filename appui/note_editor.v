module appui

import gg
import math { floor, ceil, mod }
import std.log

import app { Project }
import audio.objs { Note, Pattern }
import std { Color }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, ActionList, Piano, NoteUI, Playhead }
import appui.tools.note_editor_tools { NoteEditorToolSkeleton, ToolSelectNotes, ToolMoveNotes, ToolCutNotes, ToolPlaceNotes, ToolDeleteNotes }
import context { DlNoteEditorToolContext }

@[heap]
pub struct NoteEditor {
	pub mut:
	from                         Vec2
	size                         Vec2
	
	project                      &Project         = unsafe { nil }
	
	scroll_x                     f64
	scroll_y                     f64
	pixels_per_beat              f64              = 60.0
	header_height                f64              = 60.0
	
	shown_notes                  int              = 12 * 6 + 1
	
	colors                       []Color          = [
		Color.hex("#ff8383"), Color.hex("#f17633"),
		Color.hex("#3a994c"), Color.hex("#56a2e8"),
		Color.hex("#b594ff"), Color.hex("#b8bdc2"),
		Color.hex("#aa8d84")
	]
	selected_color               int
	hovering_color               int              = -1
	
	notes                        []&NoteUI        = []
	
	playing                      bool
	playhead                     Playhead         = Playhead{}
	note_snapping                f64              = 0.5 // bars
	
	piano                        Piano            = Piano{}
	piano_width                  f64              = 180.0
	
	tools                        []NoteEditorToolSkeleton = [
		// ToolSelectNotes{},
		// ToolMoveNotes{},
		// ToolCutNotes{},
		// ToolPlaceNotes{},
		// ToolDeleteNotes{}
	]
	selected_tool                int
	
	pub:
	note_inside_drag_dist        f64              = 4.0
	note_outside_drag_dist       f64              = 12.0
	scrub_snapping               f64              = 0.5
	
	mut:
	panning                      bool
	pattern                      &Pattern         = unsafe { nil }
	pattern_selector             ?ActionList
	dragging_note_handles        bool
	note_drag_step               f64
}

const note_tags := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

pub fn (mut editor NoteEditor) init(mut ui UI, mut project Project) {
	editor.project = project
	editor.init_tools(mut ui, mut project)
}

pub fn (mut editor NoteEditor) draw(mut ui UI) {
	ui.push_scissor(a: editor.from, b: editor.from + editor.size)
	
	ui.push_scissor(a: editor.from + Vec2{0.0, editor.header_height}, b: editor.from + editor.size)
	editor.draw_piano(mut ui, editor.from + Vec2{0.0, editor.header_height}, editor.size - Vec2{0.0, editor.header_height})
	editor.draw_notes(mut ui)
	editor.draw_bar_lines(mut ui)
	ui.pop_scissor()
	
	editor.draw_color_selection(mut ui)
	editor.draw_tools(mut ui)
	editor.draw_playhead(mut ui)
	
	// Update mouse
	if editor.panning {
		ui.set_cursor(.resize_all)
	} else if editor.hovering_color != -1 {
		ui.set_cursor(.pointing_hand)
	}
	
	ui.pop_scissor()
	editor.update_playback()
}

pub fn (mut editor NoteEditor) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	is_inside_window := Rect2.from_size(editor.from, editor.size).is_point_inside(mpos)
	
	// Control headbar events
	editor.control_playhead(event)!
	editor.control_tool_bar(mut ui, event)!
	
	// Select Color
	editor.hovering_color = -1
	for i, _ in editor.colors {
		size := Vec2{20, 20}
		pos := editor.from + Vec2{editor.size.x, editor.header_height} - Vec2{size.x * 0.5, size.y * 0.5} - Vec2{20, -20} + Vec2{0.0, (size.y + ui.style.list_gap * 2.0) * f64(i)}
		if pos.x <= mpos.x && mpos.x < pos.x + size.x  &&  pos.y <= mpos.y && mpos.y < pos.y + size.y {
			editor.hovering_color = i
		}
	}
	
	if event.typ == .mouse_down && editor.hovering_color != -1 {
		editor.selected_color = editor.hovering_color
		editor.update_tool_colors()
		return uilib.surpress_event()
	}
	
	// Move piano preview around
	if is_inside_window && event.typ == .mouse_scroll {
		if event.modifiers == 0b1 || editor.scroll_x > 0 {
			editor.scroll_x -= event.scroll_y * ui.style.scroll_speed
		} else {
			editor.scroll_y -= event.scroll_y * ui.style.scroll_speed
		}
	}
	
	// > Pan preview
	if event.typ == .mouse_move && editor.panning {
		editor.scroll_x -= event.mouse_dx * ui.style.pan_speed
		editor.scroll_y -= event.mouse_dy * ui.style.pan_speed
	}
	
	if event.typ == .mouse_down && event.mouse_button == .middle && is_inside_window {
		editor.panning = true
		return uilib.surpress_event()
	} else if event.typ == .mouse_up && event.mouse_button == .middle {
		editor.panning = false
		return uilib.surpress_event()
	}
	
	// > Clamp scrolling
	if editor.scroll_x < 0.0 { editor.scroll_x = 0.0 }
	if editor.scroll_y < 0.0 { editor.scroll_y = 0.0 }
	if editor.scroll_y + (editor.size.y - editor.header_height) > editor.piano.total_piano_height() {
		editor.scroll_y = editor.piano.total_piano_height() - (editor.size.y - editor.header_height)
	}
	
	if editor.panning || (is_inside_window && event.typ == .mouse_scroll) {
		return uilib.surpress_event()
	}
	
	// Control tools
	editor_rect := Rect2{editor.from + Vec2{0.0, editor.header_height}, editor.from + editor.size}
	if editor_rect.is_point_inside(ui.mpos) || event.typ == .mouse_up {
		editor.tools[editor.selected_tool].event(event)
	}
}



pub fn (mut editor NoteEditor) draw_piano(mut ui UI, from Vec2, size Vec2) {
	// Draw piano
	editor.piano.from = from
	editor.piano.size = Vec2{editor.piano_width, size.y}
	editor.piano.offset = editor.scroll_y
	editor.piano.draw_piano(mut ui)
	
	// Draw piano rails
	for n, rect in editor.piano.get_piano_rails(from + Vec2{editor.piano.size.x, 0.0}, size) {
		// > Black
		if [1, 3, 6, 8, 10].contains(n % 12) {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_contrast.alpha(0.08).get_gx()
			)
		}
		
		// > White
		else {
			ui.ctx.draw_rect_filled(
				f32(rect.a.x), f32(rect.a.y),
				f32(rect.size().x), f32(rect.size().y),
				ui.style.color_contrast.alpha(0.2).get_gx()
			)
		}
	}
}


pub fn (mut editor NoteEditor) draw_notes(mut ui UI) {
	rect := Rect2{a: editor.from + Vec2{editor.piano_width, editor.header_height}, b: editor.from + editor.size}
	ui.push_scissor(rect)
	rails := editor.piano.get_piano_rails(rect.a + Vec2{editor.piano.size.x, 0.0}, rect.size())
	
	for mut note_ui in editor.notes {
		// > Move and resize note into rails
		rail := rails[int(note_ui.note.id)] or {
			log.warn("Tried to draw note out of range : ${note_ui}")
			continue
		}
		fromx := editor.from.x + editor.piano_width + note_ui.note.from * editor.pixels_per_beat - editor.scroll_x
		sizex := note_ui.note.len * editor.pixels_per_beat
		
		note_ui.from = Vec2{fromx, rail.a.y}
		note_ui.size = Vec2{sizex, rail.size().y}
		
		// > Draw Note
		selected_color := editor.colors[editor.selected_color] or { Color.hex("#ffffff") }
		is_hashed := note_ui.get_color() != selected_color
		note_ui.is_colored = !is_hashed
		note_ui.draw(mut ui, is_hashed)
	}
	
	ui.pop_scissor()
}


pub fn (editor NoteEditor) draw_bar_lines(mut ui UI) {
	ui.push_scissor(a: editor.from + Vec2{editor.piano_width - 1, editor.header_height * 0.75}, b: editor.from + editor.size)
	
	// Draw beat & bar lines
	lines := int(ceil(editor.size.x / editor.pixels_per_beat)) + 1
	for l in 0..lines {
		beat := int(floor(f64(l + editor.scroll_x / editor.pixels_per_beat)))
		line_pos := editor.piano_width + f64(l) * editor.pixels_per_beat - mod(editor.scroll_x, editor.pixels_per_beat)
		over_header_extension := if beat % 4 == 0 { 0.25 } else { 0.0 }
		ui.ctx.draw_line(
			f32(editor.from.x + line_pos), f32(editor.from.y + editor.header_height * (1.0 - over_header_extension)),
			f32(editor.from.x + line_pos), f32(editor.from.y + editor.size.y),
			if beat % 4 == 0 { ui.style.color_grey.alpha(0.8).get_gx() } else { ui.style.color_grey.alpha(0.2).get_gx() }
		)
		
		// Draw bar counter
		if beat % 4 == 0 {
			ui.ctx.draw_text(
				int(editor.from.x + line_pos + 2.0), int(editor.from.y + editor.header_height * (1.0 - over_header_extension)),
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


pub fn (mut editor NoteEditor) draw_playhead(mut ui UI) {
	editor.playhead.scroll_x = editor.scroll_x
	editor.playhead.px_per_beat = editor.pixels_per_beat
	playhead_offset := Vec2{editor.piano_width, editor.header_height}
	editor.playhead.from = editor.from + playhead_offset
	editor.playhead.size = editor.size - playhead_offset
	editor.playhead.draw(mut ui)
}



pub fn (editor NoteEditor) draw_color_selection(mut ui UI) {
	for i, color in editor.colors {
		size := Vec2{20, 20}
		pos := editor.from + Vec2{editor.size.x, editor.header_height} - Vec2{size.x * 0.5, size.y * 0.5} - Vec2{20, -20} + Vec2{0.0, (size.y + ui.style.list_gap * 2.0) * f64(i)}
		ui.ctx.draw_rounded_rect_filled(
			f32(pos.x), f32(pos.y),
			f32(size.x), f32(size.y),
			f32(ui.style.rounding),
			color.get_gx()
		)
		
		if i == editor.selected_color {
			inset := 2.0
			ui.ctx.draw_rounded_rect_filled(
				f32(pos.x + inset), f32(pos.y + inset),
				f32(size.x - inset * 2.0), f32(size.y - inset * 2.0),
				f32(ui.style.rounding - inset),
				ui.style.color_panel.get_gx()
			)
			ui.draw_rect(
				pos + Vec2.v(inset),
				size - Vec2.v(inset * 2.0),
				radius: ui.style.rounding - inset
				fill_color: color.darken(0.2)
				fill_type: .double
			)
		}
	}
}



// Presents all headbar data except for the bar line counter ( handelerd in draw_bar_lines )
pub fn (mut editor NoteEditor) draw_tools(mut ui UI) {
	// Draw vertical split line
	ui.ctx.draw_line(
		f32(editor.from.x),                 f32(editor.from.y + editor.header_height * 0.5),
		f32(editor.from.x + editor.size.x), f32(editor.from.y + editor.header_height * 0.5),
		ui.style.color_panel.get_gx()
	)
	
	// Draw pattern selector
	pattern_name := if editor.pattern == unsafe { nil } { "---" } else { editor.pattern.name }
	icon_size := editor.header_height * 0.5 - ui.style.padding * 2.0
	ui.ctx.draw_line(
		f32(editor.from.x + editor.piano_width), f32(editor.from.y + editor.header_height * 0.5),
		f32(editor.from.x + editor.piano_width), f32(editor.from.y + editor.header_height),
		ui.style.color_panel.get_gx()
	)
	
	ui.ctx.draw_text(
		int(editor.from.x + ui.style.padding * 2.0), int(editor.from.y + editor.header_height * 0.75),
		pattern_name,
		color: ui.style.color_text.alpha(0.65).get_gx()
		size: int(icon_size)
		align: .left
		vertical_align: .middle
		family: ui.style.font_regular
	)
	
	// Draw play buttons
	bar_center := Vec2{editor.from.x + editor.size.x * 0.5, editor.from.y}
	ui.draw_icon(
		if editor.playing { "tool-pause" } else { "tool-play" },
		bar_center - Vec2{icon_size * 0.5, -2.0},
		Vec2.v(icon_size),
		ui.style.color_text
	)
	
	// Draw list of tools
	mut tool_position := editor.from + Vec2.v(ui.style.padding)
	tool_size := Vec2.v(icon_size)
	tool_icon_padding := 2.0
	for i, mut tool in editor.tools {
		// > Draw tool icon
		ui.draw_icon(
			tool.icon,
			tool_position + Vec2.v(tool_icon_padding),
			tool_size - Vec2.v(tool_icon_padding * 2.0),
			if editor.selected_tool == i { tool.color } else { ui.style.color_grey }
		)
		
		// > Update mouse cursor
		if Rect2.from_size(tool_position, tool_size).is_point_inside(ui.mpos) {
			ui.set_cursor(.pointing_hand)
		}
		
		// > Move next tool position
		tool_position.x += tool_size.x + ui.style.padding
	}
	
	
	// Call draw function on selected tool
	editor_rect := Rect2{editor.from + Vec2{editor.piano.size.x, editor.header_height}, editor.from + editor.size}
	ui.push_scissor(editor_rect)
	ui.cursor_locked = !editor_rect.is_point_inside(ui.mpos)
	editor.tools[editor.selected_tool].draw()
	ui.pop_scissor()
	ui.cursor_locked = false
}


pub fn (mut editor NoteEditor) update_playback() {
	editor.project.set_playing(editor.playing && editor.pattern != unsafe { nil })
	
	if editor.playing && editor.pattern != unsafe { nil } {
		// pattern_length := f64_min(editor.pattern.get_total_length(), 4.0)
		// pattern_length_realtime := pattern_length * (editor.project.bpm / 60.0)
		/*
		for next_frame_time > pattern_length_realtime {
			next_frame_time -= pattern_length_realtime
		}
		*/
		// println(next_frame_time)
	}
	
	editor.playhead.pos = editor.project.get_playback_beat_time()
}


pub fn (mut editor NoteEditor) control_playhead(event &gg.Event) ! {
	editor.project.set_playback_target_pattern(editor.pattern)
	
	editor.playhead.event(event)!
	if editor.playhead.on_drag == none && editor.pattern != unsafe { nil } {
		editor.playhead.on_drag = fn [mut editor] (t f64) {
			/*
			editor.project.play_preview_pcm_frames(
				editor.project.get_pattern_pcm_frames(
					editor.pattern,
					editor.playhead_pos,
					u32(1.0 / 5.0 * f64(editor.project.sample_rate))
				)
			)
			*/
			// TODO : Add playback mask here
			// editor.project.set_playback_target_pattern(editor.pattern)
			
			editor.project.seek_playback_time(t)
		}
	}
}

pub fn (mut editor NoteEditor) control_tool_bar(mut ui UI, event &gg.Event) ! {
	if event.typ != .mouse_down { return }
	
	// Control list of tools
	mut tool_position := editor.from + Vec2.v(ui.style.padding)
	tool_size := Vec2.v(editor.header_height * 0.5 - ui.style.padding * 2.0)
	for i, _ in editor.tools {
		// > Update selected tool on click
		if Rect2.from_size(tool_position, tool_size).is_point_inside(ui.mpos) {
			editor.selected_tool = i
		}
		
		// > Move next tool position
		tool_position.x += tool_size.x + ui.style.padding
	}
	
	// Control play button
	icon_size := editor.header_height * 0.5 - ui.style.padding * 2.0
	bar_center := Vec2{editor.from.x + editor.size.x * 0.5, editor.from.y}
	play_button_rect := Rect2.from_size(bar_center - Vec2{icon_size * 0.5, -2.0}, Vec2.v(icon_size))
	if event.typ == .mouse_down {
		if play_button_rect.is_point_inside(ui.mpos) {
			editor.playing = !editor.playing
		}
	}
}


pub fn (mut editor NoteEditor) open_pattern(pattern &Pattern) {
	editor.pattern = pattern
	editor.notes = NoteUI.from_pattern(pattern)
	
	// attach new reference to pattern for each tool
	/*
	for mut tool in editor.tools {
		tool.pattern = pattern
	}
	*/
}


// ========== TOOLS ==========

pub fn (editor NoteEditor) get_pattern() &Pattern {
	return editor.pattern
}

pub fn (mut editor NoteEditor) add_note_ui(note_ui &NoteUI) {
	editor.notes << note_ui
}

pub fn (mut editor NoteEditor) remove_note_ui(note_ui &NoteUI) {
	idx := editor.notes.index(note_ui)
	if idx != -1 {
		editor.notes.delete(idx)
	}
}

pub fn (editor NoteEditor) get_note_uis() []&NoteUI {
	return editor.notes
}


pub fn (mut editor NoteEditor) init_tools(mut ui UI, mut project Project) {
	mut tool_ctx := DlNoteEditorToolContext.new(mut ui, mut editor, mut project)
	
	editor.tools << ToolSelectNotes{ctx: tool_ctx}
	editor.tools << ToolMoveNotes{ctx: tool_ctx}
	editor.tools << ToolCutNotes{ctx: tool_ctx}
	editor.tools << ToolPlaceNotes{ctx: tool_ctx}
	editor.tools << ToolDeleteNotes{ctx: tool_ctx}
	
	//  TODO : Save Tool Context in Project to allow for live addon-adding
	
	editor.update_tool_colors()
}

fn (mut editor NoteEditor) update_tool_colors() {
	for mut tool in editor.tools {
		tool.ctx.active_color = editor.colors[editor.selected_color] or { Color.hex("#ff0000") }
	}
}

/*
Next simplified TODO:
- Implement new event system into more components
- Note dragging & removing
- Simple saving to test loading
- Instrument selection & note highlighting in note editor
- Split note editor into multiple files to clean up code

TO FIX:
- Bug, where dragging a note's length isn't clamped
- Bug, wher dragging a note's length with the mouse out of the note editor's bounds ( i.e. Piano, Rack , etc. ) stops the dragging ( also continues after release out of bounds )
*/
