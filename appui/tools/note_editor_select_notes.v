module tools

import gg
import sokol.sapp

import uilib { UI, NoteUI, FooterHook }
import std.geom2 { Vec2, Rect2 }
import std { Color }

@[heap]
pub struct ToolSelectNotes {
	pub:
	icon                    string            = "tool-select"
	color                   Color             = Color.hex("#ff8dbc")
	
	pub mut:
	conv_note2world         ToolFnNoteToWorld = unsafe { nil }
	conv_world2note         ToolFnWorldToNote = unsafe { nil }
	
	note_uis                []&NoteUI
	hovering_note           &NoteUI           = unsafe { nil }
	pre_selected_notes      []&NoteUI
	
	drag_from_time          f64               = 80.0
	drag_from_id            int               = 20
	drag_to_time            ?f64
	drag_to_id              ?int
	dragging_rect           bool
	
}

pub fn (tool ToolSelectNotes) get_cursor() sapp.MouseCursor {
	if tool.hovering_note != unsafe { nil } {
		return .pointing_hand
	}
	return .default
}

pub fn (mut tool ToolSelectNotes) on_ui_event(mut ui UI, event &gg.Event) {
	hovered_note := get_note_at_pos(ui.mpos, tool.note_uis)
	tool.hovering_note = hovered_note
	
	// > Show tooltip on footer bar
	ui.call_hook("footer", &FooterHook{msg: "`lmb` to select, `shift+lmb` to multi-select", event_typ: .mouse_move}) or {  }
	
	if event.typ == .mouse_down && event.mouse_button == .left {
		// > Deselect all notes if not shift held
		if event.modifiers & 0b1 != 0b1 {
			for mut note in tool.note_uis {
				note.is_selected = false
			}
		}
		
		// > Update note selection
		if tool.hovering_note != unsafe { nil } {
			tool.hovering_note.is_selected = !tool.hovering_note.is_selected
		}
		
		// > Update dragging rect start
		tool.drag_from_time, tool.drag_from_id = tool.conv_world2note(ui.mpos)
	}
	
	if event.typ == .mouse_move && event.mouse_button == .left {
		if !tool.dragging_rect {
			tool.start_dragging()
		}
	}
	
	// Drag selection rect
	if tool.dragging_rect && event.typ == .mouse_move {
		time, mut id := tool.conv_world2note(ui.mpos)
		if id == tool.drag_from_id { id -= 1 } // TODO : Fix weridly-shaped selection grid
		tool.drag_to_time = time
		tool.drag_to_id = id
		tool.update_selection()
	}
	
	if event.typ == .mouse_up && event.mouse_button == .left {
		tool.dragging_rect = false
		tool.drag_to_time = 0.0
		tool.drag_to_id = 0
		
		if tool.dragging_rect {
			tool.stop_dragging()
		}
	}
}

pub fn (mut tool ToolSelectNotes) draw(mut ui UI) {
	// Draw selection rect
	// TODO : Implement proper start- and end selection
	if !tool.dragging_rect { return }
	pos1 := tool.conv_note2world(tool.drag_from_time, tool.drag_from_id)
	pos2 := tool.conv_note2world(tool.drag_to_time or { 0.0 }, tool.drag_to_id or { 0 })
	a := Vec2{f64_min(pos1.x, pos2.x), f64_min(pos1.y, pos2.y)}
	b := Vec2{f64_max(pos1.x, pos2.x), f64_max(pos1.y, pos2.y)}
	ui.draw_rect(
		a,
		b - a,
		
		fill_color: Color.hex("#00000000")
		radius: ui.style.rounding
		
		outline_color: ui.style.color_text
		outline: 4.0
	)
}


// Pre-Saves all previously selected notes and actives selection
fn (mut tool ToolSelectNotes) start_dragging() {
	tool.dragging_rect = true
	
	// > Track notes that were selected beforehand
	tool.pre_selected_notes.clear()
	for mut selected_note in get_selected_notes(tool.note_uis) {
		tool.pre_selected_notes << selected_note
	}
}

// Deactives selection and removes pre-selection buffer
fn (mut tool ToolSelectNotes) stop_dragging() {
	tool.dragging_rect = true
	tool.pre_selected_notes.clear()
}


// Updates the selection state of all notes to select every note in the seleciton rectangle and pre-saved selection notes
fn (mut tool ToolSelectNotes) update_selection() {
	// > Select every note in selection rectangle
	if tool.drag_to_time == none || tool.drag_to_id == none { return }
	selection_rect := Rect2{Vec2{tool.drag_from_time, tool.drag_from_id}, Vec2{tool.drag_to_time or { 0.0 }, tool.drag_to_id or { 0 }}}
	for mut note_ui in tool.note_uis {
		if !note_ui.is_colored { continue }
		note_rect := Rect2.from_size(Vec2{note_ui.note.from, note_ui.note.id - 1}, Vec2{note_ui.note.len, 1})
		selected := Rect2.get_overlap_area(selection_rect, note_rect) > 0.0
		note_ui.is_selected = selected
	}
	
	// > Select notes that have been selected before dragging
	for mut note_ui in tool.pre_selected_notes {
		note_ui.is_selected = true
	}
}
