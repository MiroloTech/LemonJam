module appui

import gg

import std.geom2 { Vec2 }
import std { Color }
import uilib { UI, Button }

/*
The Browser panel allows you to load isntruments, sounds and effects into the project by right-clicking and selecting "Add to Rack"
Richt-click options include:
- Add to Rack
- Replace selected Rack Element
- Remove from Browser
- Locate in Explorer
*/

pub struct BrowserElement {
	pub mut:
	title         string
	descritpion   string
	icon          string
	button        Button
}

pub fn (element BrowserElement) get_height(ui UI) f64 {
	return 32.0
}

pub fn BrowserElement.new(title string, desc string, icon string) BrowserElement {
	return BrowserElement{
		title: title
		descritpion: desc
		icon: icon
		button: Button{
			title: title
			typ: .outline
			align: .left
		}
	}
}

@[heap]
pub struct BrowserGroup {
	pub mut:
	title         string
	color         Color
	is_unfolded   bool                  = true
	elements      []BrowserElement
	button        Button
}

pub fn BrowserGroup.new(title string, color Color, elements []BrowserElement) &BrowserGroup {
	mut browser_group := &BrowserGroup{
		title: title
		color: color
		elements: elements
		button: Button{
			typ: .text
			title: title + " > "
			align: .left
			
		}
	}
	
	// Connect fold / unfold action
	browser_group.button.user_data = browser_group
	browser_group.button.on_pressed = fn (user_data voidptr) {
		mut group := unsafe { &BrowserGroup(user_data) }
		group.is_unfolded = !group.is_unfolded
	}
	
	return browser_group
}

pub struct Browser {
	pub mut:
	from          Vec2
	size          Vec2
	
	scroll       f64
	groups       []&BrowserGroup
}

pub fn (mut browser Browser) draw(mut ui UI) {
	// Create scissor rect
	ui.push_scissor(
		a: browser.from
		b: browser.from + browser.size
	)
	
	// Draw groups and elements
	margin := ui.style.margin
	mut y := browser.from.y - browser.scroll + margin
	for mut group in browser.groups {
		// > Draw parent button
		group.button.from = Vec2{browser.from.x + margin, y}
		group.button.size.x = browser.size.x - margin
		group.button.size.y = 26.0
		
		group.button.color_primary = group.color
		group.button.color_secondary = group.color.darken(0.2)
		group.button.title = group.title + if group.is_unfolded { " v " } else { " > " }
		
		group.button.draw(mut ui)
		
		y += group.button.size.y + ui.style.list_gap
		if !group.is_unfolded { continue }
		
		for mut element in group.elements {
			// > Draw button
			element.button.from = Vec2{browser.from.x + margin, y}
			element.button.size.x = browser.size.x - margin * 2
			element.button.size.y = element.get_height(ui)
			
			element.button.color_primary = group.color
			element.button.color_secondary = group.color.darken(0.2)
			
			element.button.draw(mut ui)
			
			y += element.button.size.y + ui.style.list_gap
		}
	}
	
	// Remove scissor rect
	ui.pop_scissor()
}


pub fn (mut browser Browser) event(mut ui UI, event &gg.Event) ! {
	for mut group in browser.groups {
		// > Control parent buttons
		group.button.event2(mut ui, event)!
		
		for mut element in group.elements {
			// > Control individual buttons
			element.button.event2(mut ui, event)!
			if element.button.is_hovered {
				ui.call_hook("footer", &FooterHook{msg: element.descritpion, event_typ: .mouse_move}) or { continue }
			}
		}
	}
}
