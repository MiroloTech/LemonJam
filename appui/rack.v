module appui

import gg

import std { Color }
import std.geom2 { Vec2, Rect2 }
import uilib { UI, Button }

/*
The Rack shows all patterns, instruments, effects and sounds loaded and / or used in the project.
- Clicking on a pattern opens it in the pattern editor
	> Patterns get an extra add button at the end, which creates a new pattern to use
- Clicking on a sound opens it in the sound editor
	> Patterns get an extra add button at the end, which prompts you to record a new sound or load it from the User's PC
- Clicking on an instrument opens its settings panel
- Clicking on an effect opens its settings panel
*/

pub struct RackElement {
	pub mut:
	title        string
	button       Button
	height       f64                = 28.0
	
	user_data    voidptr
	on_open      ?fn (user_data voidptr)
}

pub fn RackElement.new(title string, color Color) RackElement {
	return RackElement{
		title: title
		button: Button{
			title: title
			typ: .grey
			color_primary: color
			color_secondary: color.darken(0.1)
		}
	}
}

pub fn (mut element RackElement) connect_hook(func fn (user_data voidptr), user_data voidptr) {
	element.on_open = func
	element.user_data = user_data
	
	element.button.on_pressed = func
	element.button.user_data = user_data
}


pub struct RackResource {
	pub mut:
	title        string
	color        Color              = Color.hex("#ffffff")
	icon         string
	
	elements     []RackElement
	selected     int                = -1
	
	add_btn      ?Button
	user_data    voidptr
	on_add       ?fn (user_data voidptr)
}

pub fn RackResource.new(mut ui UI, title string, color Color, icon string, elements []RackElement, on_btn_press_fn ?fn (user_data voidptr)) &RackResource {
	return &RackResource{
		title: title
		color: color
		icon: icon
		elements: elements
		add_btn: if on_btn_press_fn != none {
			Button{
				title: "+"
				typ: .flat
				user_data: &ui
				on_pressed: on_btn_press_fn
				
				color_primary: color
				color_secondary: color.darken(0.1)
				font_size: 32
			}
		} else { ?Button(none) }
	}
}


pub struct Rack {
	pub mut:
	from         Vec2
	size         Vec2
	
	tab_height   f64                = 36.0
	tabs         []&RackResource
	tab_open     int
	tab_hovered  int                = -1
}

pub fn (mut rack Rack) draw(mut ui UI) {
	mut y := rack.from.y
	
	// Draw tabs
	for i, tab in rack.tabs {
		size := Vec2{rack.size.x / f64(rack.tabs.len), rack.tab_height}
		from := rack.from + Vec2{size.x * f64(i), 0.0}
		
		// > Draw BG if selected
		if rack.tab_open == i || rack.tab_hovered == i {
			ui.ctx.draw_rect_filled(
				f32(from.x), f32(from.y),
				f32(size.x), f32(size.y),
				ui.style.color_panel.get_gx()
			)
		}
		
		if rack.tab_open == i {
			ui.ctx.draw_rect_filled(
				f32(from.x), f32(from.y + size.y - 2.0),
				f32(size.x), f32(2.0),
				tab.color.get_gx()
			)
		}
		
		// > Draw icon
		icon_size := Vec2.v(f64_min(size.x, size.y) - ui.style.strong_padding)
		icon_from := from + size * Vec2{0.5, 0.5} - icon_size * Vec2{0.5, 0.5}
		ui.draw_icon(tab.icon, icon_from, icon_size, tab.color)
	}
	y += rack.tab_height + ui.style.padding
	
	// Update mouse cursor
	if rack.tab_hovered != -1 {
		ui.cursor = .pointing_hand
	}
	
	// Draw elements in tab
	mut resource := &rack.tabs[rack.tab_open] or { return }
	for mut element in resource.elements {
		element.button.from = Vec2{rack.from.x + ui.style.padding, y}
		element.button.size = Vec2{rack.size.x - ui.style.padding * 2.0, element.height}
		element.button.draw(mut ui)
		
		y += element.height + ui.style.list_gap
	}
	
	// Draw optional add button
	if resource.add_btn != none {
		resource.add_btn.from = Vec2{rack.from.x + ui.style.padding, y}
		resource.add_btn.size = Vec2{rack.size.x - ui.style.padding * 2.0, 24.0}
		resource.add_btn.draw(mut ui)
	}
}


pub fn (mut rack Rack) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	// Find hovered tab
	if event.typ == .mouse_move {
		rack.tab_hovered = -1
		
		for i, _ in rack.tabs {
			size := Vec2{rack.size.x / f64(rack.tabs.len), rack.tab_height}
			from := rack.from + Vec2{size.x * f64(i), 0.0}
			if Rect2{from, from + size}.is_point_inside(mpos) {
				rack.tab_hovered = i
			}
		}
	}
	
	// Set selected tab to hovered tab if pressed
	if event.typ == .mouse_down && rack.tab_hovered != -1 {
		rack.tab_open = rack.tab_hovered
	}
	
	// Control every element in selected tab
	mut resource := &rack.tabs[rack.tab_open] or { return }
	for mut element in resource.elements {
		if Rect2{rack.from + Vec2{0, rack.tab_height}, rack.from + rack.size}.is_point_inside(mpos) {
			element.button.event(mut ui, event)
		} else {
			element.button.is_hovered = false
			element.button.is_pressed = false
		}
	}
	
	// Draw optional add button
	if resource.add_btn != none {
		if Rect2{rack.from + Vec2{0, rack.tab_height}, rack.from + rack.size}.is_point_inside(mpos) || event.typ == .mouse_up {
			resource.add_btn.event(mut ui, event)
			// TODO : Fix the non-reaction of this button
		} else {
			resource.add_btn.is_hovered = false
		}
	}
}
