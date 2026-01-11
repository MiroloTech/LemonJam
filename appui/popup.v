module appui

import gg

import std.geom2 { Vec2, Rect2 }
import uilib { UI, Button }

pub struct Popup {
	pub mut:
	size           Vec2
	title          string
	text           string
	buttons        []PopupButton
}

pub enum PopupButtonTyp {
	standart
	primary
	secondary
	error
	warning
}

pub struct PopupButton {
	pub mut:
	text           string
	icon           string
	typ            PopupButtonTyp
	
	mut:
	button         Button
}


pub fn (popup Popup) draw(mut ui UI) {
	
}

pub fn (popup Popup) event(mut ui UI, event &gg.Event) {
	
}

