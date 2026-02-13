module appui

import gg
import log

// import std { Color }
import std.geom2 { Vec2 }
import app { Project }
import audio.objs { Pattern }
import uilib { UI, Toaster, HSplit, VSplit }
import appui.popups { NewPatternPopup, NewSessionPopup }

pub struct Window {
	pub mut:
	toaster                Toaster                   = Toaster{}
	header                 Header                    = Header{}
	footer                 Footer                    = Footer{}
	
	main_hsplit            HSplit                    = HSplit{}
	browser                Browser                   = Browser{}
	rack                   Rack                      = Rack{}
	main_vsplit            VSplit                    = VSplit{}
	note_editor            &NoteEditor               = &NoteEditor{}
	timeline               &Timeline                 = &Timeline{}
	
	project                &Project                  = unsafe { nil }
	
	// TODO : [x] Browser, Rack, Routing Graph, Timeline, Sound Editor, Pattern Editor
}

pub fn (mut win Window) init(mut ui UI) {
	// Init toaster
	win.toaster = Toaster{}
	win.toaster.from = Vec2{400 - 40, 1000 - 40}
	win.toaster.size = Vec2{320.0, 30.0}
	
	// Init project
	win.project = &Project{}
	win.project.ui_ptr = &ui
	
	// Init header
	win.header.options["File"] = [
		HeaderAction{ name: "Render"         hotkey: "Ctrl+Shift+E" },
		HeaderAction{ is_seperator: true },
		HeaderAction{ name: "Save"           hotkey: "Ctrl+S" },
		HeaderAction{ name: "Save As"        hotkey: "Ctrl+Shift+S" },
		HeaderAction{ is_seperator: true },
		HeaderAction{ name: "Open"           hotkey: "Ctrl+O" },
		HeaderAction{ name: "Open Recent" },
		HeaderAction{ is_seperator: true },
		HeaderAction{ name: "Exit" },
	]
	win.header.options["Edit"] = [
		HeaderAction{ name: "Copy"          hotkey: "Ctrl+C" },
		HeaderAction{ name: "Paste"         hotkey: "Ctrl+V" },
		HeaderAction{ name: "Cut"           hotkey: "Ctrl+X" },
		HeaderAction{ name: "Undo"          hotkey: "Ctrl+Z" },
		HeaderAction{ name: "Redo"          hotkey: "Ctrl+Y" },
	]
	
	win.header.options["Session"] = [
		HeaderAction{ name: "Start Session"                                 on_selected: fn [mut win] (_ string, ui_ptr voidptr) {
			mut ui := unsafe { &UI(ui_ptr) }
			ui.popups << NewSessionPopup.new(
				mut ui,
				ui.top_left() + Vec2.v(60),
				ui.bottom_right() - Vec2.v(120),
				mut win.project
			)
		} user_data: mut ui }
		HeaderAction{ name: "Stop Session"  disabled: true }
	]
	win.header.init(mut ui)
	
	// Init horizontal panel sizing
	win.main_hsplit.splits = [300.0, 500.0]
	win.main_vsplit.splits = [500.0]
	
	// Init browser
	win.browser.groups = [
		BrowserGroup.new("Instrument", ui.style.color_instrument, [
			BrowserElement.new("Drum Kit", "It's a Drum Kit", "")
			BrowserElement.new("Flute", "It's a Flute", "")
			BrowserElement.new("Electric Keys", "It's an Electric Keyboard", "")
		]),
		BrowserGroup.new("Effects", ui.style.color_effect, [
			BrowserElement.new("Bit Crush", "", "")
			BrowserElement.new("Radio Cracks", "", "")
		])
	]
	
	// Init rack
	mut pattern_rack := RackResource.new(mut ui, "Pattern", ui.style.color_pattern, "tab-pattern", [], none)
	
	// > Attach popup call
	pattern_rack.set_on_btn_press_fn(mut ui, fn [mut pattern_rack, mut win] (user_data voidptr) {
		mut ui := unsafe { &UI(user_data) }
		
		// Open naming popup
		pos := if pattern_rack.add_btn == none { ui.center() } else { pattern_rack.add_btn.from + Vec2{0.0, pattern_rack.add_btn.size.y + ui.style.padding} }
		ui.popups << NewPatternPopup.new(
			ui,
			pos,
			Vec2{300, 125},
			win.project
			// unsafe { nil }
		)
	})
	
	ui.hooks["add-to-pattern-list"] = fn [mut win, mut pattern_rack, mut ui] (pattern_ptr voidptr) {
		pattern := unsafe { &Pattern(pattern_ptr) }
		mut element := RackElement.new(pattern.name,  ui.style.color_pattern)
		element.connect_hook(fn [mut ui] (pattern_ptr voidptr) {
			// Call hook
			ui.call_hook("open-pattern", pattern_ptr) or { return }
		}, pattern)
		pattern_rack.elements << element
	}
	
	// Manage showing of selected patterns
	win.project.new_pattern_user_data = pattern_rack
	/*
	win.project.on_ui_new_pattern = fn (pattern &Pattern, rack_ptr voidptr, ui_ptr voidptr) {
		mut rack := unsafe { &RackResource(rack_ptr) }
		mut ui := unsafe { &UI(ui_ptr) }
		mut element := RackElement.new(pattern.name,  ui.style.color_pattern)
		element.connect_hook(fn [mut ui] (pattern_ptr voidptr) {
			// Call hook
			ui.call_hook("open-pattern", pattern_ptr) or { return }
		}, pattern)
		rack.elements << element
	}
	// TODO : Remove obsulete on_ui_new_pattern
	*/
	
	// TODO : Now display project instruments, effects and sounds in Rack
	// TODO : Properly implement racks with hooks on re-creation of pattern
	
	win.rack.tabs = [
		pattern_rack,
		
		RackResource.new(mut ui, "Instruments",  ui.style.color_instrument,     "tab-instrument",  [
			RackElement.new("Electric Keys",  ui.style.color_instrument),
			RackElement.new("Drum Kit",       ui.style.color_instrument),
		], none)
		
		RackResource.new(mut ui, "Effects",      ui.style.color_effect,         "tab-effect",      [
			RackElement.new("Radio Cracks",   ui.style.color_effect),
		], none)
		
		RackResource.new(mut ui, "Sounds",       ui.style.color_sound,          "tab-sound",       [
			RackElement.new("Voice",          ui.style.color_sound),
			RackElement.new("Riser-06",       ui.style.color_sound),
		], fn (user_data voidptr) {
			mut ui := unsafe { &UI(user_data) }
			ui.call_hook("new-sound", unsafe { nil }) or { return }
		}) // > Connect hook to create new sound
	]
	
	// Init note editor
	/*
	note1  := Note{from: 0.0, len: 4.0, id: 24 + 1}
	note2  := Note{from: 0.0, len: 4.0, id: 24 + 6}
	note3  := Note{from: 0.0, len: 4.0, id: 24 + 8}
	note4  := Note{from: 0.0, len: 4.0, id: 24 + 10}
	
	note5  := Note{from: 4.0, len: 4.0, id: 24 + 1}
	note6  := Note{from: 4.0, len: 4.0, id: 24 + 5}
	note7  := Note{from: 4.0, len: 4.0, id: 24 + 8}
	
	note8  := Note{from: 8.0, len: 4.0, id: 24 + -1}
	note9  := Note{from: 8.0, len: 4.0, id: 24 + 4}
	note10 := Note{from: 8.0, len: 4.0, id: 24 + 8}
	
	note11 := Note{from: 12.0, len: 4.0, id: 24 + -1}
	note12 := Note{from: 12.0, len: 4.0, id: 24 + 3}
	note13 := Note{from: 12.0, len: 4.0, id: 24 + 6}
	note14 := Note{from: 12.0, len: 4.0, id: 24 + 11}
	win.note_editor.notes = [ &note1, &note2, &note3, &note4, &note5, &note6, &note7, &note8, &note9, &note10, &note11, &note12, &note13, &note14 ]
	*/
	
	win.project.load_from_file("${@VMODROOT}/temp.json") or { log.error("Failed to load project form file : ${err}") } // TEMP & TODO
	win.project.update_ui_from_save_file(mut ui)
	// win.toaster.add_toast("Save file loaded", .info, 2.0) // TODO : Move the loading to seperate function and buffer toasts until first redraw
	
	// UNSAFE !!!!
	win.note_editor.init_tools()
	win.note_editor.open_pattern(win.project.patterns[0] or { unsafe { nil } })
	ui.hooks["open-pattern"] = fn [mut win] (pattern_ptr voidptr) { win.note_editor.open_pattern(pattern_ptr) }
	
	// Call initialization hook for user button
	ui.call_hook("on-username-change", win.project.user_name.str) or {  }
	
	/*
	for note in win.note_editor.notes {
		win.note_editor.note_colors[note] = Color.hex("#ff8383")
	}
	*/
	
	// Init footer
	lj_version := @VMOD_FILE.find_between("version: '", "'")
	win.footer.display_until("Welcome to LemonJam v${lj_version}", .mouse_down)
	
	// > Init footer hook
	ui.hooks["footer"] = win.footer.display_until_hook
	ui.hooks["toast-error"] = fn [mut win] (msg_ptr voidptr) {
		msg := unsafe { cstring_to_vstring(msg_ptr) }
		win.toaster.add_toast(msg, .error, 2.0)
	}
	ui.hooks["toast-info"] = fn [mut win] (msg_ptr voidptr) {
		msg := unsafe { cstring_to_vstring(msg_ptr) }
		win.toaster.add_toast(msg, .info, 2.0)
	}
	
	
	// ui.popups << NewSessionPopup.new(ui, ui.top_left() + Vec2{80, 80}, ui.bottom_right() - Vec2{160, 160}, mut win.project)
	
	// Test-Init Timeline
	win.timeline.reload(ui, win.project) or {
		win.toaster.add_toast("Failed to reload timeline", .error, 2.0)
		log.error("Failed to reload timeline")
	}
}

// NOTICE : Make sure, that the drawing order is mostyle inverted from the event controlling order. This mostly insures, that events from a top level don't propagate to lower levels

pub fn (mut win Window) frame(mut ui UI) {
	// Draw browser
	browser_x, browser_width := win.main_hsplit.get_split(0)
	win.browser.from = Vec2{browser_x,     win.main_hsplit.from.y}
	win.browser.size = Vec2{browser_width, win.main_hsplit.size.y}
	win.browser.draw(mut ui)
	
	// Draw rack
	rack_x, rack_width := win.main_hsplit.get_split(1)
	win.rack.from = Vec2{rack_x,     win.main_hsplit.from.y}
	win.rack.size = Vec2{rack_width, win.main_hsplit.size.y}
	win.rack.draw(mut ui)
	
	// > Pre-Calculate v-split sizing
	vsplit_x, vsplit_width := win.main_hsplit.get_split(2)
	
	// Draw Note Editor
	note_editor_y, note_editor_height := win.main_vsplit.get_split(1)
	win.note_editor.from = Vec2{vsplit_x, note_editor_y}
	win.note_editor.size = Vec2{vsplit_width, note_editor_height}
	win.note_editor.draw(mut ui)
	
	// Draw Timeline
	timeline_y, timelint_height := win.main_vsplit.get_split(0)
	win.timeline.from = Vec2{vsplit_x, timeline_y}
	win.timeline.size = Vec2{vsplit_width, timelint_height}
	win.timeline.draw(mut ui)
	
	// Draw main vertical splitter
	win.main_vsplit.from = Vec2{vsplit_x,     win.main_hsplit.from.y}
	win.main_vsplit.size = Vec2{vsplit_width, win.main_hsplit.size.y}
	win.main_vsplit.draw(mut ui)
	
	// Draw main horizontal splitter
	win.main_hsplit.from = Vec2{0, win.header.height}
	win.main_hsplit.size = ui.bottom_right() - Vec2{0, win.header.height + win.footer.height}
	win.main_hsplit.draw(mut ui)
	
	// Draw headbar
	win.header.draw(mut ui)
	
	// Draw footer
	win.footer.draw(mut ui)
	
	// Draw toaster
	win.toaster.from = ui.bottom_right() - Vec2{40, 40}
	win.toaster.draw(mut ui)
	
	// ui.draw_icon("not-found", Vec2{0, 0}, Vec2{100, 100}, Color.hex("#f1f6f0"))
}

pub fn (mut win Window) event(mut ui UI, event &gg.Event) {
	// Control footer
	win.footer.event(mut ui, event)
	
	// Control header
	win.header.event(mut ui, event) or { return }
	
	// Control main hsplit
	win.main_hsplit.event(mut ui, event) or { return }
	
	// Control browser
	win.browser.event(mut ui, event) or { return }
	
	// Control rack
	win.rack.event(mut ui, event) or { return }
	
	// Control main vsplit
	win.main_vsplit.event(mut ui, event) or { return }
	
	// Control Note Editor
	win.note_editor.event(mut ui, event) or { return }
	
	// Control Timeline
	win.timeline.event(mut ui, event) or { return }
}

pub fn (mut win Window) cleanup(mut ui UI) {
	
}

