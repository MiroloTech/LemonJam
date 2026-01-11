module appui

import gg

import std { Color }
import audio.objs { Note }
import std.geom2 { Vec2 }
import uilib { UI, Toaster, HSplit, VSplit }

pub struct Window {
	pub mut:
	toaster                Toaster                   = Toaster{}
	header                 Header                    = Header{}
	footer                 Footer                    = Footer{}
	
	main_hsplit            HSplit                    = HSplit{}
	browser                Browser                   = Browser{}
	rack                   Rack                      = Rack{}
	main_vsplit            VSplit                    = VSplit{}
	note_editor            NoteEditor                = NoteEditor{}
	
	// TODO : [x] Browser, Rack, Routing Graph, Timeline, Sound Editor, Pattern Editor
}

pub fn (mut win Window) init(mut ui UI) {
	// Init toaster
	win.toaster = Toaster{}
	win.toaster.from = Vec2{400 - 40, 1000 - 40}
	win.toaster.size = Vec2{320.0, 30.0}
	
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
	win.rack.tabs = [
		RackResource.new(mut ui, "Pattern",      ui.style.color_pattern,        "tab-pattern",     [
			RackElement.new("Jazz Beat",      ui.style.color_pattern),
			RackElement.new("Bass",           ui.style.color_pattern),
			RackElement.new("Chords",         ui.style.color_pattern),
		], fn (user_data voidptr) {
			mut ui := unsafe { &UI(user_data) }
			ui.call_hook("new-pattern", unsafe { nil }) or { return }
		}) // > Connect hook to create new pattern
		
		RackResource.new(mut ui, "Instruments",  ui.style.color_instrument,     "tab-instrument",  [
			RackElement.new("Electric Keys",  ui.style.color_pattern),
			RackElement.new("Drum Kit",       ui.style.color_pattern),
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
	
	for _, note in win.note_editor.notes {
		win.note_editor.note_colors[note] = Color.hex("#ff8383")
	}
	
	// Init footer
	lj_version := @VMOD_FILE.find_between("version: '", "'")
	win.footer.display_until("Welcome to LemonJam v${lj_version}", .mouse_down)
	
	// > Init footer hook
	ui.hooks["footer"] = win.footer.display_until_hook
}

// NOTICE : Make sure, that the drawing order is mostyle inverted from the event controlling order. This mostly insures, that events from a top level don't propagate to lower levels
// TODO : Implement event blocking system for higher levels (stop rest of function from getting that event call)

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
}

pub fn (mut win Window) cleanup(mut ui UI) {
	
}

