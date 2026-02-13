module popups

import gg
import log

// import std { Color }
import app { Project }
import std.geom2 { Vec2, Rect2, Tri2 }
import uilib { UI, Event, Button, LineEdit }
import mirrorlib { Server }

const world_map_data := $embed_file("uilib/assets/world-simplified.svg").to_string()

@[heap]
pub struct NewSessionPopup {
	pub mut:
	from            Vec2
	size            Vec2
	
	world_from      Vec2
	world_size      Vec2
	
	project         &Project
	servers         shared []Server
	
	hovering_server int                     = -1
	selected_server int                     = -1
	
	earth_shape     []Tri2
	lakes_shape     []Tri2
	
	bar_height      f64                     = 30.0
	
	// TODO : Add max. people picker and shwocase checkbox
	password        LineEdit
	start_btn       Button
	cancel_btn      Button
}

pub fn NewSessionPopup.new(mut ui UI, from Vec2, size Vec2, mut project Project) NewSessionPopup {
	earth_shape, lakes_shape := triangulate_world_map()
	mut popup := NewSessionPopup{
		from: from
		size: size
		
		project: project
		
		earth_shape: earth_shape
		lakes_shape: lakes_shape
		
		// Init password, start_btn, etc.
		password: LineEdit{
			placeholder: "Optional Password"
		}
		start_btn: Button{
			typ: .solid
			title: "Start Session"
		}
		cancel_btn: Button{
			typ: .dark
			title: "Cancel"
		}
	}
	
	spawn fn (mut popup NewSessionPopup) {
		// TODO : Create a footer message here
		popup.fetch_servers()
	}(mut &popup)
	
	return popup
}

pub fn (mut popup NewSessionPopup) draw(mut ui UI) {
	// Resize full-screen popup
	window_padding := 80.0
	popup.from = Vec2.v(window_padding)
	popup.size = ui.get_window_size() - Vec2.v(window_padding * 2.0)
	popup.world_from = popup.from + Vec2.v(ui.style.strong_padding)
	popup.world_size = popup.size - Vec2.v(ui.style.strong_padding * 2.0) - Vec2{0.0, popup.bar_height + ui.style.padding * 2.0}
	
	// Draw BG
	ui.draw_rect(
		popup.from,
		popup.size,
		fill_color: ui.style.color_panel
		radius: ui.style.rounding
	)
	
	// Draw Map
	for raw_tri in popup.earth_shape {
		tri := raw_tri.scale(popup.world_size).offset(popup.world_from)
		ui.ctx.draw_triangle_filled(
			f32(tri.a.x), f32(tri.a.y),
			f32(tri.b.x), f32(tri.b.y),
			f32(tri.c.x), f32(tri.c.y),
			// ui.style.color_primary.alpha(0.5).get_gx()
			ui.style.color_grey.brighten(0.05).get_gx()
		)
	}
	for raw_tri in popup.lakes_shape {
		tri := raw_tri.scale(popup.world_size).offset(popup.world_from)
		ui.ctx.draw_triangle_filled(
			f32(tri.a.x), f32(tri.a.y),
			f32(tri.b.x), f32(tri.b.y),
			f32(tri.c.x), f32(tri.c.y),
			ui.style.color_panel.get_gx()
		)
	}
	
	// Draw Servers
	rlock popup.servers {
		for i, server in popup.servers {
			p := Vec2{(server.lon + 180.0) / 360.0, (-server.lat + 90.0) / 180.0} * popup.world_size + popup.world_from
			dot_size := 8.0
			dot_color := if server.ping < 20.0 { ui.style.color_correct } else { if server.ping < 30.0 { ui.style.color_warning } else { ui.style.color_error } }
			// Draw Server if live
			if server.status == .live {
				// > Loading
				if server.ping < 0.0 {
					ui.ctx.draw_circle_filled(
						f32(p.x - 10.0), f32(p.y),
						f32(dot_size / 2.0),
						ui.style.color_grey.brighten(0.2).get_gx()
					)
					ui.ctx.draw_circle_filled(
						f32(p.x), f32(p.y),
						f32(dot_size / 2.0),
						ui.style.color_grey.brighten(0.2).get_gx()
					)
					ui.ctx.draw_circle_filled(
						f32(p.x + 10.0), f32(p.y),
						f32(dot_size / 2.0),
						ui.style.color_grey.brighten(0.2).get_gx()
					)
				}
				
				// > Ping
				else {
					ui.ctx.draw_circle_filled(
						f32(p.x), f32(p.y),
						f32(dot_size),
						dot_color.get_gx()
					)
					
					if i == popup.selected_server {
						rring := dot_size + 3.0
						ui.ctx.draw_ellipse_thick(
							f32(p.x), f32(p.y),
							f32(rring), f32(rring),
							f32(2.0),
							dot_color.get_gx()
						)
					}
				}
			}
			// Draw as grey server if not online
			else if server.status != .coming_soon {
				ui.ctx.draw_circle_filled(
					f32(p.x), f32(p.y),
					f32(dot_size),
					ui.style.color_grey.brighten(0.2).get_gx()
				)
			}
		}
	}
	
	// Show Server data
	if popup.hovering_server != -1 {
		// > Control mouse
		ui.cursor = .pointing_hand
		
		// > Draw data preview
		server := popup.servers[popup.hovering_server] or { return }
		p := Vec2{(server.lon + 180.0) / 360.0, (-server.lat + 90.0) / 180.0} * popup.world_size + popup.world_from
		
		from := p + Vec2{20.0, -20.0}
		size := Vec2{120.0, 40.0}
		
		// > Draw body
		ui.draw_rect(
			from,
			size,
			
			radius: ui.style.rounding
			outline: 2.0
			
			fill_color: ui.style.color_grey
			outline_color: ui.style.color_grey
		)
		
		// > Draw title
		ui.ctx.draw_text(
			int(from.x + ui.style.padding), int(from.y + ui.style.padding * 0.5),
			server.title,
			color: ui.style.color_text.get_gx()
			size: ui.style.font_size_title
			family: ui.style.font_bold
		)
		
		// > Draw ping
		ping_color := if server.ping < 0.0 {
			ui.style.color_grey.brighten(0.2)
		} else {
			if server.ping < 20.0 {
				ui.style.color_correct
			} else {
				if server.ping < 30.0 {
					ui.style.color_warning
				} else {
					ui.style.color_error
				}
			}
		}
		ui.ctx.draw_text(
			int(from.x + ui.style.padding), int(from.y + size.y - ui.style.padding * 0.5),
			if server.status != .live { "offline" } else { if server.ping >= 0.0 { "${int(server.ping)}ms" } else { "Loading..." } },
			color: ping_color.get_gx()
			size: ui.style.font_size
			vertical_align: .bottom
			family: ui.style.font_mono
		)
	}
	
	// TODO : Draw Buttons at each 15%, Create Chekbox & Player Selecter With Action List
	
	// Draw UI Controls
	bottom_left := popup.world_from + Vec2{0.0, popup.world_size.y + ui.style.padding}
	popup.password.from = bottom_left
	popup.password.size = Vec2{0.5 * popup.world_size.x, popup.bar_height}
	popup.password.draw(mut ui)
	
	popup.start_btn.from = popup.password.from + Vec2{popup.password.size.x + ui.style.strong_padding, ui.style.padding}
	popup.start_btn.size = Vec2{0.25 * popup.world_size.x, popup.bar_height}
	popup.start_btn.disabled = popup.selected_server == -1
	popup.start_btn.draw(mut ui)
	
	popup.cancel_btn.from = popup.password.from + Vec2{popup.start_btn.size.x + popup.password.size.x + ui.style.strong_padding * 2.0, ui.style.padding}
	popup.cancel_btn.size = Vec2{0.25 * popup.world_size.x - ui.style.strong_padding * 2.0, popup.bar_height}
	popup.cancel_btn.draw(mut ui)
}

pub fn (mut popup NewSessionPopup) event(mut ui UI, event &gg.Event) ! {
	mpos := Vec2{event.mouse_x, event.mouse_y}
	if event.typ == .mouse_move {
		popup.hovering_server = -1
		rlock popup.servers {
			for i, server in popup.servers {
				p := Vec2{(server.lon + 180.0) / 360.0, (-server.lat + 90.0) / 180.0} * popup.world_size + popup.world_from
				dot_size := 8.0
				if mpos.distance_to(p) <= dot_size * 1.5 {
					popup.hovering_server = i
				}
			}
		}
	} else if event.typ == .mouse_down && popup.hovering_server != -1 {
		popup.selected_server = popup.hovering_server
		rlock popup.servers {
			if server := popup.servers[popup.selected_server] {
				if server.status != .live {
					popup.selected_server = -1
				}
			} else {
				popup.selected_server = -1
			}
		}
	}
	
	// Control Session creation Controls
	popup.password.event(mut ui, event)
	popup.start_btn.event2(mut ui, event)!
	popup.cancel_btn.event2(mut ui, event)!
	
	if popup.cancel_btn.is_pressed {
		popup.close(mut ui)
	}
	
	if popup.start_btn.is_pressed && popup.selected_server != -1 {
		rlock popup.servers {
			popup.project.start_session(popup.servers[popup.selected_server]) or {
				ui.call_hook("toast-error", "Failed to start session : ${err}".str) or {  }
				log.error("Failed to start session : ${err}")
			}
		}
		popup.close(mut ui)
	}
}

pub fn (mut popup NewSessionPopup) close(mut ui UI) {
	idx := ui.popups.index(popup)
	if idx != -1 {
		ui.popups.delete(idx)
	}
}


pub fn (mut popup NewSessionPopup) fetch_servers() {
	// TODO : Internet logic here
	temp := '{
    "dbg": {
        "title": "Test",
        "status": "live",
        "ip": "127.0.0.1",
        "lon": 142.0,
        "lat": -81.3
    },
    "de": {
        "title": "Germany",
        "status": "live",
        "ip": "216.58.206.46",
        "lon": 9.1,
        "lat": 48.8
    },
    "au": {
        "title": "Australia",
        "status": "live",
        "ip": "185.15.59.226",
        "lon": 150.7,
        "lat": -33.7
    },
    "us": {
        "title": "United States",
        "status": "live",
        "ip": "140.82.121.3",
        "lon": -121.2,
        "lat": 37.7
    },
    "as": {
        "title": "China",
        "status": "live",
        "ip": "151.101.65.140",
        "lon": 121.1,
        "lat": 31.1
    },
    "br": {
        "title": "Brazil",
        "status": "offline",
        "ip": "142.250.185.174",
        "lon": -38.7,
        "lat": -12.8
    }
}'
	lock popup.servers {
		popup.servers = Server.load_list_from_json(temp) or {
			log.error("Failed to fetch list of servers : ${err}")
			return
		}
		
		for mut server in popup.servers {
			go server.update_ping()
		}
		// println(popup.servers)
	}
}



// ========== UTIL ==========
@[direct_array_access]
fn triangulate_world_map() ([]Tri2, []Tri2) {
	mut color := ""
	mut transform := []f64{}
	mut d := ""
	mut scaling := Vec2{1.0, 1.0}
	
	mut shape_earth := [][]Vec2{}
	mut shape_lakes := [][]Vec2{}
	
	for line_raw in world_map_data.split("\n") {
		line := line_raw.find_between("<", ">")
		if line.starts_with("svg") {
			view_box_data := line.find_between("viewBox=\"", "\"").split(" ")
			scaling.x = view_box_data[2].f64()
			scaling.y = view_box_data[3].f64()
		}
		else if line.starts_with("g") {
			transform_data := line.find_between("matrix(", ")").split(" ")
			transform = []f64{}
			for vstr in transform_data {
				transform << vstr.f64()
			}
			// g_id = line.find_between(" id=\"", "\"").replace("patch_", "").int()
		} else if line.starts_with("path") {
			d = line.find_between(" d=\"", "\"")
			// Fix werid data like this: 8.6341.88106.2203
			mut d_clean := ""
			
			mut is_valid_decimal := true
			for c8 in d.bytes() {
				c := c8.ascii_str()
				if c == " " {
					is_valid_decimal = true
				}
				
				if c == "." {
					if is_valid_decimal {
						d_clean += "."
						is_valid_decimal = false
					} else {
						d_clean += " ."
					}
				} else {
					d_clean += c
				}
			}
			
			color = line.find_between("fill=\"", "\"")
			
			// Parse 'd_clean' data
			mut instruction := ""
			mut pts := []Vec2{}
			mut temp := Vec2{}
			// mut is_y := false
			mut i := 0
			for vstr in d_clean.split(" ") {
				v := vstr.f64()
				if vstr == "" { continue }
				if v == 0.0 {
					instruction = vstr
					if !["m", "l", "h", "H", "v", "V", "z"].contains(instruction) {
						println("Unsuported svg instruction : ${instruction}")
					}
					i = 0
					continue
				}
				
				// Especially create first point
				match instruction {
					"m" {
						if i == 0 {
							pts << Vec2{v, 0.0}
						}
						else if i == 1 {
							pts[0].y = v
						}
						
						// Folow next points based on last one
						else if i > 1 {
							last_point := pts[pts.len - 1]
							if i % 2 == 0 {
								temp = Vec2{v, 0.0}
							} else {
								temp.y = v
								pts << last_point + temp
							}
						}
					}
					"l" {
						if i % 2 == 0 {
							pts << Vec2{v, 0.0}
						} else {
							pts[pts.len - 1].y = v
						}
					}
					"v" {
						last_point := pts[pts.len - 1]
						pts << last_point + Vec2{0.0, v}
					}
					"V" {
						last_point := pts[pts.len - 1]
						pts << Vec2{last_point.x, v}
					}
					"h" {
						last_point := pts[pts.len - 1]
						pts << last_point + Vec2{v, 0.0}
					}
					"H" {
						last_point := pts[pts.len - 1]
						pts << Vec2{v, last_point.y}
					}
					"z" {  }
					else {  }
				}
				
				i++
			}
			
			// > Project points through matrix
			for p in 0..pts.len {
				pts[p] = apply_matrix(pts[p], transform) / scaling
			}
			
			if pts.len < 3 { continue }
			
			// Add points to proper shape
			if color == "#fff" {
				shape_lakes << pts
			} else {
				shape_earth << pts
			}
		}
	}
	
	
	// Triangulate points
	mut tris_earth := []Tri2{}
	mut tris_lakes := []Tri2{}
	
	for island in shape_earth {
		tris_earth << Tri2.triangulate(island)
	}
	for lake in shape_lakes {
		tris_lakes << Tri2.triangulate(lake)
	}
	
	return tris_earth, tris_lakes
}

@[inline]
fn apply_matrix(p Vec2, matrix []f64) Vec2 {
	return Vec2{
		matrix[0] * p.x + matrix[2] * p.y + matrix[4],
		matrix[1] * p.x + matrix[3] * p.y + matrix[5]
	}
}
