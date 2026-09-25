module context

import gg
import sokol.sapp { MouseCursor }

import math { floor }
import std.geom2 { Vec2, Rect2 }
import std { Color }
import uilib { UI, Style, NoteUI, Piano }
import audio.objs { Note, Pattern, Instrument }

pub interface NetworkHost {
	get_active_instrument() &Instrument
	
	mut:
	new_note_simple(from f64, len f64, id int, color Color, mut pattern Pattern, instrument &Instrument) &Note
	update_note(note &Note)
	delete_note(mut pattern Pattern, note &Note)
}

pub interface PatternHost {
	get_pattern() &Pattern
	
	mut:
	add_note_ui(note_ui &NoteUI)
	remove_note_ui(note_ui &NoteUI)
	get_note_uis() []&NoteUI
	
	from                Vec2
	size                Vec2
	piano               Piano
	
	header_height       f64
	pixels_per_beat     f64
	scroll_x            f64
	note_snapping       f64
}

@[heap]
pub struct DlNoteEditorToolContext {
	mut:
	pattern_host           &PatternHost                                                            = unsafe { nil }
	net_host               &NetworkHost                                                            = unsafe { nil }
	
	pub mut:
	active_color           Color                                                                   = Color.hex("#ff00ff")
	
	// Cursor
	set_cursor             fn (cusror MouseCursor)                                                 @[required]
	get_cursor             fn () MouseCursor                                                       @[required]
	get_mpos               fn () Vec2                                                              @[required]
	
	// Draw calls
	// set_footer_msg         fn (msg string)                                                         @[required] // TODO : This
	draw_rect              fn (from Vec2, size Vec2, config uilib.RectConfig)                      @[required]
	draw_text              fn (pos Vec2, text string, config gg.TextCfg)                           @[required]
	draw_circle            fn (center Vec2, radius f64, color Color, empty bool)                   @[required]
	draw_line_with_config  fn (a Vec2, b Vec2, config gg.PenConfig)                                @[required]
	draw_icon              fn (icon string, from Vec2, size Vec2, color Color)                     @[required]
	get_style              fn () &Style                                                            @[required]
	
	// Note Editor Controls
	create_note_simple     fn (from f64, length f64, id int, color Color) &NoteUI                  @[required]
	delete_note            fn (note &NoteUI)                                                       @[required]
	force_update_note      fn (note &NoteUI)                                                       @[required]
	
	get_notes              fn () []&NoteUI                                                         @[required]
	get_selected_notes     fn () []&NoteUI                                                         @[required]
	
	world_to_grid          fn (pos Vec2) (f64, int)                                                @[required]
	grid_to_world          fn (time f64, id int) Vec2                                              @[required]
}

pub fn DlNoteEditorToolContext.new(mut ui UI, mut pattern_host PatternHost, mut net_host NetworkHost) &DlNoteEditorToolContext {
	return &DlNoteEditorToolContext{
		pattern_host: pattern_host
		
		set_cursor:               fn [mut ui] (cursor MouseCursor) {
			ui.cursor = cursor
		}
		get_cursor:               fn [mut ui] () MouseCursor {
			return ui.cursor
		}
		get_mpos:                 fn [mut ui] () Vec2 {
			return ui.mpos
		}
		
		draw_rect:                fn [mut ui] (from Vec2, size Vec2, config uilib.RectConfig) {
			ui.draw_rect(from, size, config)
		}
		draw_text:                fn [mut ui] (pos Vec2, text string, config gg.TextCfg) {
			ui.ctx.draw_text(int(pos.x), int(pos.y), text, config)
		}
		draw_circle:              fn [mut ui] (center Vec2, radius f64, color Color, empty bool) {
			if empty {
				ui.ctx.draw_circle_empty(f32(center.x), f32(center.y), f32(radius), color.get_gx())
			} else {
				ui.ctx.draw_circle_filled(f32(center.x), f32(center.y), f32(radius), color.get_gx())
			}
		}
		draw_line_with_config:    fn [mut ui] (a Vec2, b Vec2, config gg.PenConfig) {
			ui.ctx.draw_line_with_config(f32(a.x), f32(a.y), f32(b.x), f32(b.y), config)
		}
		draw_icon:                fn [mut ui] (icon string, from Vec2, size Vec2, color Color) {
			ui.draw_icon(icon, from, size, color)
		}
		get_style:                fn [mut ui] () &Style {
			return &ui.style
		}
		
		create_note_simple:       fn [mut pattern_host, mut net_host] (from f64, length f64, id int, color Color) &NoteUI {
			if pattern_host == unsafe { nil } { return unsafe { nil } }
			mut pattern := pattern_host.get_pattern()
			
			mut note := net_host.new_note_simple(from, length, id, color, mut pattern, net_host.get_active_instrument())
			
			// > Add to pattern
			// pattern.notes << note
			// pattern.instruments[note] = net_host.get_active_instrument()
			
			// > Add to UI
			mut note_ui := &NoteUI{
				note: note
				is_colored: true
			}
			pattern_host.add_note_ui(note_ui)
			return note_ui
		}
		delete_note:               fn [mut pattern_host, mut net_host] (note_ui &NoteUI) {
			if pattern_host == unsafe { nil } { return }
			mut pattern := pattern_host.get_pattern()
			
			// > Remove from UI
			pattern_host.remove_note_ui(note_ui)
			
			// > Remove from pattern
			net_host.delete_note(mut pattern, note_ui.note)
		}
		force_update_note:         fn [mut pattern_host, mut net_host] (note_ui &NoteUI) {
			if pattern_host == unsafe { nil } { return }
			net_host.update_note(note_ui.note)
		}
		
		get_notes:                 fn [mut pattern_host] () []&NoteUI {
			return pattern_host.get_note_uis()
		}
		get_selected_notes:        fn [mut pattern_host] () []&NoteUI {
			mut notes := []&NoteUI{}
			for note in pattern_host.get_note_uis() {
				if note.is_selected {
					notes << note
				}
			}
			return notes
		}
		
		world_to_grid:             fn [mut pattern_host] (pos Vec2) (f64, int) {
			if pattern_host == unsafe { nil } { return 0.0, 1 }
			rect := Rect2{
				a: pattern_host.from + Vec2{pattern_host.piano.size.x, pattern_host.header_height}
				b: pattern_host.from + pattern_host.size - Vec2{pattern_host.piano.size.x, pattern_host.header_height}
			}
			mut fromx := (pos.x - pattern_host.from.x - pattern_host.piano.size.x + pattern_host.scroll_x) / pattern_host.pixels_per_beat
			fromx = f64_max(floor(fromx / pattern_host.note_snapping) * pattern_host.note_snapping, 0.0)
			rail_id := pattern_host.piano.get_rail_id(pos.y, rect.a + Vec2{pattern_host.piano.size.x, 0.0}, rect.size())
			return fromx, rail_id
		}
		grid_to_world:             fn [mut pattern_host] (time f64, id int) Vec2 {
			if pattern_host == unsafe { nil } { return Vec2{0.0, 0.0} }
			rect := Rect2{
				a: pattern_host.from + Vec2{pattern_host.piano.size.x, pattern_host.header_height}
				b: pattern_host.from + pattern_host.size - Vec2{pattern_host.piano.size.x, pattern_host.header_height}}
			rails := pattern_host.piano.get_piano_rails(rect.a + Vec2{pattern_host.piano.size.x, 0.0}, rect.size())
			
			rail := rails[id] or {
				return Vec2.zero()
			}
			
			fromx := pattern_host.from.x + pattern_host.piano.size.x + time * pattern_host.pixels_per_beat - pattern_host.scroll_x
			return Vec2{fromx, rail.a.y}
		}
	}
}
