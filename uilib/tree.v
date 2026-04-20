module uilib

import os
import gg

import std.geom2 { Vec2, Rect2 }

pub struct Tree {
	pub mut:
	from            Vec2
	size            Vec2
	
	on_select       ?fn (path string, os_path string)
	elements        []&TreeElement
	
	hovering_path   ?string
}

pub fn Tree.from_file_system(parent_path string, exclude []string, exclude_top_folder bool) Tree {
	top_element := TreeElement.from_file_system("", parent_path, exclude, if exclude_top_folder { -1 } else { 0 })
	if exclude_top_folder {
		return Tree{elements: top_element.children}
	}
	return Tree{elements: [top_element]}
}

pub fn (tree Tree) draw(mut ui UI) {
	// Update mouse cursor
	if tree.hovering_path != none {
		ui.cursor = .pointing_hand
	}
	
	// Draw Tree
	mut remaining_elements := tree.elements.clone()
	mut y := tree.from.y + ui.style.padding
	height := f64(ui.style.font_size) + ui.style.list_gap
	for remaining_elements.len > 0 {
		element := remaining_elements.pop_left()
		mut x := tree.from.x + f64(element.depth) * 20.0 + ui.style.padding * 2.0
		selection_rect := Rect2.from_size(Vec2{0.0, y}, Vec2{tree.size.x, height})
		
		// Draw selection
		if tree.hovering_path != none {
			if element.path == tree.hovering_path {
				ui.draw_rect(
					selection_rect.a, selection_rect.size(),
					fill_color: ui.style.color_panel
				)
			}
		}
		
		// Draw icon
		icon := get_icon(element.path, element.is_folder)
		ui.draw_icon(
			icon,
			Vec2{x + ui.style.padding * 0.5, y + ui.style.padding * 0.5},
			Vec2.v(ui.style.font_size - ui.style.padding),
			ui.style.color_text
		)
		x += f64(ui.style.font_size) + ui.style.padding
		
		// Draw title
		ui.ctx.draw_text(
			int(x), int(y),
			element.title,
			family: ui.style.font_regular
			size: ui.style.font_size
			color: ui.style.color_text.get_gx()
		)
		
		y += height
		
		if !element.is_collapsed {
			for child in element.children {
				remaining_elements.insert(0, child)
			}
		}
	}
}

pub fn (mut tree Tree) event(mut ui UI, event &gg.Event) ! {
	tree.hovering_path = ?string(none)
	
	mut remaining_elements := tree.elements.clone()
	mut y := tree.from.y + ui.style.padding
	height := f64(ui.style.font_size) + ui.style.list_gap
	for remaining_elements.len > 0 {
		mut element := remaining_elements.pop_left()
		selection_rect := Rect2.from_size(Vec2{0.0, y}, Vec2{tree.size.x, height})
		
		if selection_rect.is_point_inside(ui.mpos) {
			tree.hovering_path = element.path
			
			if event.typ == .mouse_down && event.mouse_button == .left {
				if element.is_folder {
					element.is_collapsed = !element.is_collapsed
				} else if tree.on_select != none {
					tree.on_select(element.path, element.os_path)
				}
			}
		}
		
		
		y += height
		
		if !element.is_collapsed {
			for child in element.children {
				remaining_elements.insert(0, child)
			}
		}
	}
}


@[heap]
pub struct TreeElement {
	pub mut:
	title         string
	path          string
	os_path       string
	depth         int
	children      []&TreeElement
	
	is_folder     bool
	is_collapsed  bool
}

// Recursively creates a tree element from the file system tree
pub fn TreeElement.from_file_system(parent_path string, parent_os_path string, exclude []string, depth int) &TreeElement {
	// Create base tree element
	mut element := &TreeElement{title: get_title_from_path(parent_os_path), path: parent_path, os_path: parent_os_path children: [], depth: depth}
	
	// Loop through every child (if element is folder)
	entries := os.ls(parent_os_path) or { [] }
	for entry in entries {
		// > Exclude certain file / folder types by exclude list
		os_path := os.join_path(parent_os_path, entry)
		path := if parent_path == "" { entry } else { parent_path + "/" + entry }
		mut valid := true
		for e in exclude {
			if e.starts_with("*") && (path.ends_with(e.replace("*", "")) || path == e) {
				valid = false
				break
			} else {
				if os.is_dir(os_path) && e.ends_with("/") && e.replace("/", "") == path {
					valid = false
					break
				} else if !os.is_dir(os_path) && !e.ends_with("/") && e == path {
					valid = false
					break
				}
			}
		}
		
		if !valid {
			continue
		}
		
		// > Create sub-tree-element recursively
		element.children << TreeElement.from_file_system(path, os_path, exclude, depth + 1)
	}
	if entries.len > 0 {
		element.is_folder = true
	}
	
	return element
}

fn get_title_from_path(path string) string {
	$if windows {
		return path.all_after_last("\\").all_before_last(".").replace("_", " ").replace("-", " ").title()
	} $else {
		return path.all_after_last("/").all_before_last(".").replace("_", " ").replace("-", " ").title()
	}
}

fn get_icon(path string, is_folder bool) string {
	if is_folder {
		return "file-folder"
	} else if path.replace("\\", "/").all_after_last("/").contains(".") {
		return match path.all_after_last(".") {
			"md"                              { "file-md" }
			"dll", "so", "dylib"              { "file-dll" }
			"png", "jpg", "bmp"               { "file-image" }
			"json"                            { "file-json" }
			else                              { "file" }
		}
	} else {
		return "file"
	}
}
