module uilib

import math { floor, ceil, sqrt, min, max, clamp, pow, sin, cos, atan }

import std { Color }
import std.geom2 { Vec2 }

const rad0   := 0.0
const rad90  := 1.57079632679
const rad180 := 3.14159265359
const rad270 := 4.71238898038
const rad360 := 6.28318530718

pub fn (mut ui UI) draw_striped_rect(from Vec2, size Vec2, color Color) {
	length := size.x + size.y
	line_count := int(floor(length / ui.style.line_spacing))
	
	for i in 0..line_count {
		v := f64(i) * ui.style.line_spacing
		
		x := if v <= size.x { v } else { size.x } + from.x
		y := if v >= size.x { v - size.x } else { 0 } + from.y
		
		x2 := if v >= size.y { v - size.y } else { 0 } + from.x
		y2 := if v <= size.y { v } else { size.y } + from.y
		
		ui.ctx.draw_line(
			f32(x), f32(y),
			f32(x2), f32(y2),
			color.get_gx()
		)
	}
}


pub fn (mut ui UI) draw_double_striped_rect(from Vec2, size Vec2, color Color) {
	length := size.x + size.y
	line_count := int(floor(length / ui.style.line_spacing))
	
	for i in 0..line_count {
		v := f64(i) * ui.style.line_spacing
		
		x := if v <= size.x { v } else { size.x } + from.x
		y := if v >= size.x { v - size.x } else { 0 } + from.y
		
		x2 := if v >= size.y { v - size.y } else { 0 } + from.x
		y2 := if v <= size.y { v } else { size.y } + from.y
		
		x3 := if v <= size.x { size.x - v } else { 0 } + from.x
		y3 := if v >= size.x { v - size.x } else { 0 } + from.y
		
		x4 := if v >= size.y { size.x - (v - size.y) } else { size.x } + from.x
		y4 := if v <= size.y { v } else { size.y } + from.y
		
		
		ui.ctx.draw_line(
			f32(x), f32(y),
			f32(x2), f32(y2),
			color.get_gx()
		)
		
		ui.ctx.draw_line(
			f32(x3), f32(y3),
			f32(x4), f32(y4),
			color.get_gx()
		)
	}
}


pub fn (mut ui UI) draw_rounded_striped_rect(from Vec2, size Vec2, rtl f64, rtr f64, rbl f64, rbr f64, color Color) {
	// Itterate through every line
	spacing := ui.style.rect_stripe_spacing
	imin := -int(ceil(size.x / spacing))
	imax := int(ceil(size.y / spacing))
	for i in imin..imax {
		// > Calculate points intersecting the base rect with y = x - c
		c := f64(i) * spacing
		ax := max(-c, 0.0)
		ay := max(c, 0.0)
		bx := min(-c + size.y, size.x)
		by := min(c + size.x, size.y)
		mut a := Vec2{ax, ay} // top left
		mut b := Vec2{bx, by} // bottom right
		mut is_visible := true
		
		// > Apply rounding
		// >> Top Left
		if ax < rtl && ay < rtl {
			center := Vec2.v(rtl)
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rtl)
			a = intersections[0] or {
				is_visible = false
				a
			}
		}
		
		// >> Top Right
		if size.x - ax < rtr && ay < rtr {
			center := Vec2{size.x - rtr, rtr}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rtr)
			a = intersections[0] or {
				is_visible = false
				a
			}
			b = intersections[1] or {
				is_visible = false
				b
			}
		}
		
		// >> Bottom Left
		if ax < rbl && size.y - ay < rbl {
			center := Vec2{rbl, size.y - rbl}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rbl)
			a = intersections[0] or {
				is_visible = false
				a
			}
			b = intersections[1] or {
				is_visible = false
				b
			}
		}
		
		// >> Bottom Right
		if size.x - bx < rbr && size.y - by < rbr {
			center := Vec2{size.x - rbr, size.y - rbr}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rbr)
			b = intersections[1] or {
				is_visible = false
				b
			}
		}
		
		// > Draw line
		if is_visible {
			ui.ctx.draw_line(
				f32(a.x + from.x), f32(a.y + from.y),
				f32(b.x + from.x), f32(b.y + from.y),
				color.get_gx()
			)
		}
	}
}



pub fn (mut ui UI) draw_rounded_double_striped_rect(from Vec2, size Vec2, rtl f64, rtr f64, rbl f64, rbr f64, color Color) {
	// Itterate through every line
	// See : https://www.desmos.com/calculator/5l6cscjr2j
	spacing := ui.style.rect_stripe_spacing
	imin := -int(ceil(size.x / spacing))
	imax := int(ceil(size.y / spacing))
	for i in imin..imax {
		// > Calculate points intersecting the base rect with y = x - c
		c := f64(i) * spacing
		c2 := c + (size.x - size.y)
		ax := max(-c, 0.0)
		ay := max(c, 0.0)
		bx := min(-c + size.y, size.x)
		by := min(c + size.x, size.y)
		cx := max(c2, 0.0)
		cy := min(size.y + c2, size.y)
		dx := min(c2 + size.y, size.x)
		dy := max(c2 - (size.x - size.y), 0.0)
		mut point_a := Vec2{ax, ay}
		mut point_b := Vec2{bx, by}
		mut point_c := Vec2{cx, cy}
		mut point_d := Vec2{dx, dy}
		mut is_visible_ab := true
		mut is_visible_cd := true
		
		// > Apply rounding
		// >> Top Left
		if ax < rtl && ay < rtl {
			center := Vec2.v(rtl)
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rtl)
			point_a = intersections[0] or {
				is_visible_ab = false
				point_a
			}
		}
		
		// >> Top Right
		if size.x - ax < rtr && ay < rtr {
			center := Vec2{size.x - rtr, rtr}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rtr)
			point_a = intersections[0] or {
				is_visible_ab = false
				point_a
			}
			point_b = intersections[1] or {
				is_visible_ab = false
				point_b
			}
		}
		
		// >> Bottom Left
		if ax < rbl && size.y - ay < rbl {
			center := Vec2{rbl, size.y - rbl}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rbl)
			point_a = intersections[0] or {
				is_visible_ab = false
				point_a
			}
			point_b = intersections[1] or {
				is_visible_ab = false
				point_b
			}
		}
		
		// >> Bottom Right
		if size.x - bx < rbr && size.y - by < rbr {
			center := Vec2{size.x - rbr, size.y - rbr}
			intersections := geom2.intersection_circle_line(Vec2{ax, ay}, Vec2{bx, by}, center, rbr)
			point_b = intersections[1] or {
				is_visible_ab = false
				point_b
			}
		}
		
		// -----
		// >> Top Left
		if cx < rtl && cy < rtl {
			center := Vec2.v(rtl)
			intersections := geom2.intersection_circle_line(Vec2{cx, cy}, Vec2{dx, dy}, center, rtl)
			point_c = intersections[0] or {
				is_visible_cd = false
				point_c
			}
			point_d = intersections[1] or {
				is_visible_cd = false
				point_d
			}
		}
		
		// >> Top Right
		if size.x - dx < rtr && dy < rtr {
			center := Vec2{size.x - rtr, rtr}
			intersections := geom2.intersection_circle_line(Vec2{cx, cy}, Vec2{dx, dy}, center, rtr)
			point_d = intersections[1] or {
				is_visible_cd = false
				point_d
			}
		}
		
		// >> Bottom Left
		if cx < rbl && size.y - cy < rbl {
			center := Vec2{rbl, size.y - rbl}
			intersections := geom2.intersection_circle_line(Vec2{cx, cy}, Vec2{dx, dy}, center, rbl)
			point_c = intersections[0] or {
				is_visible_cd = false
				point_c
			}
		}
		
		// >> Bottom Right
		if size.x - cx < rbr && size.y - cy < rbr {
			center := Vec2{size.x - rbr, size.y - rbr}
			intersections := geom2.intersection_circle_line(Vec2{cx, cy}, Vec2{dx, dy}, center, rbr)
			point_c = intersections[0] or {
				is_visible_cd = false
				point_c
			}
			point_d = intersections[1] or {
				is_visible_cd = false
				point_d
			}
		}
		
		
		// > Draw line
		if is_visible_ab {
			ui.ctx.draw_line(
				f32(point_a.x + from.x), f32(point_a.y + from.y),
				f32(point_b.x + from.x), f32(point_b.y + from.y),
				color.get_gx()
			)
		}
		if is_visible_cd {
			ui.ctx.draw_line(
				f32(point_c.x + from.x), f32(point_c.y + from.y),
				f32(point_d.x + from.x), f32(point_d.y + from.y),
				color.get_gx()
			)
		}
	}
}

pub fn (mut ui UI) draw_specifically_rounded_rect(from Vec2, size Vec2, rtl f64, rtr f64, rbl f64, rbr f64, color Color) {
	// Corners
	x := f32(from.x)
	y := f32(from.y)
	w := f32(size.x)
	h := f32(size.y)
	
	segments := int(max(max(max(rtl, rtr), rbl), rbr))
	
	r1 := f32(clamp(rtl, 0.0, min(f64(w), f64(h)) / 2.0))
	r2 := f32(clamp(rtr, 0.0, min(f64(w), f64(h)) / 2.0))
	r3 := f32(clamp(rbl, 0.0, min(f64(w), f64(h)) / 2.0))
	r4 := f32(clamp(rbr, 0.0, min(f64(w), f64(h)) / 2.0))
	
	// > Top Left
	ui.ctx.draw_slice_filled(
		x + r1, y + r1,
		r1,
		f32(rad180), f32(rad270),
		segments, color.get_gx()
	)
	
	// > Top Right
	ui.ctx.draw_slice_filled(
		x + w - r2, y + r2,
		r2,
		f32(rad90), f32(rad180),
		segments, color.get_gx()
	)
	
	// > Bottom Left
	ui.ctx.draw_slice_filled(
		x + r3, y + h - r3,
		r3,
		f32(rad270), f32(rad360),
		segments, color.get_gx()
	)
	
	// > Bottom Right
	ui.ctx.draw_slice_filled(
		x + w - r4, y + h - r4,
		r4,
		f32(rad0), f32(rad90),
		segments, color.get_gx()
	)
	
	// > Center Polygon
	mut pts := [][]f32{}
	
	pts << [ // Top Left
		[x, y + r1],
		[x + r1, y + r1],
		[x + r1, y],
	]
	
	pts << [ // Top Right
		[x + w - r2, y],
		[x + w - r2, y + r2],
		[x + w, y + r2],
	]
	
	pts << [ // Bottom Right
		[x + w, y + h - r4],
		[x + w - r4, y + h - r4],
		[x + w - r4, y + h],
	]
	
	pts << [ // Bottom Left
		[x + r3, y + h],
		[x + r3, y + h - r3],
		[x, y + h - r3],
	]
	
	ui.ctx.draw_triangle_filled(
		pts[1][0], pts[1][1],
		pts[2][0], pts[2][1],
		pts[3][0], pts[3][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[3][0], pts[3][1],
		pts[4][0], pts[4][1],
		pts[1][0], pts[1][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[4][0], pts[4][1],
		pts[5][0], pts[5][1],
		pts[6][0], pts[6][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[6][0], pts[6][1],
		pts[7][0], pts[7][1],
		pts[4][0], pts[4][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[7][0], pts[7][1],
		pts[8][0], pts[8][1],
		pts[9][0], pts[9][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[9][0], pts[9][1],
		pts[10][0], pts[10][1],
		pts[7][0], pts[7][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[10][0], pts[10][1],
		pts[11][0], pts[11][1],
		pts[0][0], pts[0][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[0][0], pts[0][1],
		pts[1][0], pts[1][1],
		pts[10][0], pts[10][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[1][0], pts[1][1],
		pts[4][0], pts[4][1],
		pts[7][0], pts[7][1],
		color.get_gx()
	)
	ui.ctx.draw_triangle_filled(
		pts[7][0], pts[7][1],
		pts[10][0], pts[10][1],
		pts[1][0], pts[1][1],
		color.get_gx()
	)
}


pub fn (mut ui UI) draw_specifically_rounded_rect_empty(from Vec2, size Vec2, rtl f64, rtr f64, rbl f64, rbr f64, color Color) {
	// Corners
	x := f32(from.x)
	y := f32(from.y)
	w := f32(size.x)
	h := f32(size.y)
	
	segments := int(max(max(max(rtl, rtr), rbl), rbr))
	
	r1 := f32(clamp(rtl, 0.0, min(f64(w), f64(h)) / 2.0))
	r2 := f32(clamp(rtr, 0.0, min(f64(w), f64(h)) / 2.0))
	r3 := f32(clamp(rbl, 0.0, min(f64(w), f64(h)) / 2.0))
	r4 := f32(clamp(rbr, 0.0, min(f64(w), f64(h)) / 2.0))
	
	// > Top Left
	ui.ctx.draw_arc_line(
		x + r1, y + r1,
		r1,
		f32(rad180), f32(rad270),
		segments, color.get_gx()
	)
	
	// > Top Right
	ui.ctx.draw_arc_line(
		x + w - r2, y + r2,
		r2,
		f32(rad90), f32(rad180),
		segments, color.get_gx()
	)
	
	// > Bottom Left
	ui.ctx.draw_arc_line(
		x + r3, y + h - r3,
		r3,
		f32(rad270), f32(rad360),
		segments, color.get_gx()
	)
	
	// > Bottom Right
	ui.ctx.draw_arc_line(
		x + w - r4, y + h - r4,
		r4,
		f32(rad0), f32(rad90),
		segments, color.get_gx()
	)
	
	// Connectin lines
	
	// > Left
	ui.ctx.draw_line(
		f32(x), f32(y + r1),
		f32(x), f32(y + h - r3),
		color.get_gx()
	)
	
	// > Right
	ui.ctx.draw_line(
		f32(x + w), f32(y + r2),
		f32(x + w), f32(y + h - r4),
		color.get_gx()
	)
	
	// > Top
	ui.ctx.draw_line(
		f32(x + r1), f32(y),
		f32(x + w - r2), f32(y),
		color.get_gx()
	)
	
	// > Bottom
	ui.ctx.draw_line(
		f32(x + r3), f32(y + h),
		f32(x + w - r4), f32(y + h),
		color.get_gx()
	)
}



pub fn (mut ui UI) draw_rect(from Vec2, size Vec2, config RectConfig) {
	// Draw body
	// IDEA : For lenguage : n-Dimensional match cases
	from2 := from + Vec2.v(config.inset)
	size2 := size - Vec2.v(config.inset * 2.0)
	match config.fill_type {
		.full {
			if config.radius > 0.0 {
				if config.is_cleanly_rounded() {
					ui.ctx.draw_rounded_rect_filled(
						f32(from2.x), f32(from2.y),
						f32(size2.x), f32(size2.y),
						f32(config.radius - config.inset),
						config.fill_color.get_gx()
					)
				} else {
					ui.draw_specifically_rounded_rect(
						from,
						size,
						config.radius_tl or { config.radius },
						config.radius_tr or { config.radius },
						config.radius_bl or { config.radius },
						config.radius_br or { config.radius },
						config.fill_color
					)
				}
			} else {
				ui.ctx.draw_rect_filled(
					f32(from2.x), f32(from2.y),
					f32(size2.x), f32(size2.y),
					config.fill_color.get_gx()
				)
			}
		}
		.striped {
			if config.radius > 0.0 {
				ui.draw_rounded_striped_rect(
					from2,
					size2,
					(config.radius_tl or { config.radius }) - config.inset,
					(config.radius_tr or { config.radius }) - config.inset,
					(config.radius_bl or { config.radius }) - config.inset,
					(config.radius_br or { config.radius }) - config.inset,
					config.fill_color
				)
			} else {
				ui.draw_striped_rect(from2, size2, config.fill_color)
			}
		}
		.double {
			if config.radius > 0.0 {
				ui.draw_rounded_double_striped_rect(
					from2,
					size2,
					(config.radius_tl or { config.radius }) - config.inset,
					(config.radius_tr or { config.radius }) - config.inset,
					(config.radius_bl or { config.radius }) - config.inset,
					(config.radius_br or { config.radius }) - config.inset,
					config.fill_color
				)
			} else {
				ui.draw_double_striped_rect(from2, size2, config.fill_color)
			}
		}
	}
	
	// Draw outline
	if config.outline > 0.0 {
		for i in 0..int(floor(config.outline)) {
			o := f64(i)
			if config.radius > 0.0 {
				if config.is_cleanly_rounded() {
					ui.ctx.draw_rounded_rect_empty(
						f32(from2.x - o), f32(from2.y - o),
						f32(size2.x + o * 2.0), f32(size2.y + o * 2.0),
						f32(config.radius + o - config.inset),
						config.outline_color.get_gx()
					)
				} else {
					ui.draw_specifically_rounded_rect_empty(
						/*
						f32(from2.x - o), f32(from2.y - o),
						f32(size2.x + o * 2.0), f32(size2.y + o * 2.0),
						*/
						from2 + Vec2.v(o),
						size2 - Vec2.v(o * 2.0 - config.inset),
						(config.radius_tl or { config.radius }) - o - config.inset,
						(config.radius_tr or { config.radius }) - o - config.inset,
						(config.radius_bl or { config.radius }) - o - config.inset,
						(config.radius_br or { config.radius }) - o - config.inset,
						config.outline_color
					)
				}
				// TODO : Support specifically rounded empty rects here
			} else {
				ui.ctx.draw_rect_empty(
					f32(from2.x - o), f32(from2.y - o),
					f32(size2.x + o * 2.0), f32(size2.y + o * 2.0),
					config.outline_color.get_gx()
				)
			}
		}
	}
}


@[params]
pub struct RectConfig {
	pub mut:
	outline            f64
	outline_color      Color
	
	fill_color         Color
	fill_type          InfillType         = .full
	
	radius             f64
	inset              f64
	
	radius_tl          ?f64
	radius_tr          ?f64
	radius_bl          ?f64
	radius_br          ?f64
}

pub fn (config RectConfig) is_cleanly_rounded() bool {
	return config.radius_tl == none && config.radius_tr == none && config.radius_bl == none && config.radius_br == none
}

pub enum InfillType {
	full
	striped
	double
}


fn circ_edge(x f64, r f64, w f64) f64 {
	xx := min(min(x - r, 0), w - x - r)
	f := r * r - xx * xx
	if f <= 0.0 { return 0.0 }
	return r - sqrt(f)
}
