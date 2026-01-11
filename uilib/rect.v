module uilib

import math { floor, sqrt, min }

import std { Color }
import std.geom2 { Vec2 }

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


pub fn (mut ui UI) draw_rounded_striped_rect(from Vec2, size Vec2, radius f64, color Color) {
	length := size.x + size.y
	line_count := int(floor(length / ui.style.rect_stripe_spacing))
	
	for i in 0..line_count {
		v := f64(i) * ui.style.rect_stripe_spacing
		
		x := if v <= size.x { v } else { size.x }
		y := if v >= size.x { v - size.x } else { 0 }
		
		x2 := if v >= size.y { v - size.y } else { 0 }
		y2 := if v <= size.y { v } else { size.y }
		
		// > Rounding
		mut yy  := y  + circ_edge(x,  radius, size.x)
		mut yy2 := y2 - circ_edge(x2, radius, size.x)
		mut xx  := x  - circ_edge(y,  radius, size.y)
		mut xx2 := x2 + circ_edge(y2, radius, size.y)
		
		// >> Fix corners
		
		if xx == 0 && yy == 0 {
			xx += radius * 0.3
			yy += radius * 0.3
			
			xx2 += radius * 0.3
			yy2 += radius * 0.3
		}
		
		if xx == size.x && yy == 0 {
			xx -= radius * 0.3
			yy += radius * 0.3
			
			xx2 += radius * 0.3
			yy2 -= radius * 0.3
		}
		
		// > Offset
		xx += from.x
		xx2 += from.x
		yy += from.y
		yy2 += from.y
		
		ui.ctx.draw_line(
			f32(xx), f32(yy),
			f32(xx2), f32(yy2),
			color.get_gx()
		)
	}
}


pub fn (mut ui UI) draw_rounded_double_striped_rect(from Vec2, size Vec2, radius f64, color Color) {
	length := size.x + size.y
	line_count := int(floor(length / ui.style.rect_stripe_spacing))
	
	for i in 0..line_count {
		v := f64(i) * ui.style.rect_stripe_spacing
		
		x := if v <= size.x { v } else { size.x }
		y := if v >= size.x { v - size.x } else { 0 }
		
		x2 := if v >= size.y { v - size.y } else { 0 }
		y2 := if v <= size.y { v } else { size.y }
		
		x3 := if v <= size.x { size.x - v } else { 0 }
		y3 := if v >= size.x { v - size.x } else { 0 }
		
		x4 := if v >= size.y { size.x - (v - size.y) } else { size.x }
		y4 := if v <= size.y { v } else { size.y }
		
		
		// > Rounding
		mut yy  := y  + circ_edge(x,  radius, size.x)
		mut yy2 := y2 - circ_edge(x2, radius, size.x)
		mut yy3 := y3 + circ_edge(x3, radius, size.x)
		mut yy4 := y4 - circ_edge(x4, radius, size.x)
		mut xx  := x  - circ_edge(y,  radius, size.y)
		mut xx2 := x2 + circ_edge(y2, radius, size.y)
		mut xx3 := x3 + circ_edge(y3, radius, size.y)
		mut xx4:= x4 - circ_edge(y4, radius, size.y)
		
		// >> Fix corners
		if xx == 0 && yy == 0 {
			xx += radius * 0.3
			yy += radius * 0.3
			
			xx2 += radius * 0.3
			yy2 += radius * 0.3
		}
		
		if xx == size.x && yy == 0 {
			xx -= radius * 0.3
			yy += radius * 0.3
			
			xx2 += radius * 0.3
			yy2 -= radius * 0.3
		}
		
		if xx4 == size.x && yy4 == 0 {
			xx3 -= radius * 0.3
			yy3 += radius * 0.3
			
			xx4 -= radius * 0.3
			yy4 += radius * 0.3
		}
		
		if xx3 == 0 && yy3 == 0 {
			xx3 += radius * 0.3
			yy3 += radius * 0.3
			
			xx4 -= radius * 0.3
			yy4 -= radius * 0.3
		}
		
		// > Offset
		xx  += from.x
		xx2 += from.x
		xx3 += from.x
		xx4 += from.x
		yy  += from.y
		yy2 += from.y
		yy3 += from.y
		yy4 += from.y
		
		ui.ctx.draw_line(
			f32(xx), f32(yy),
			f32(xx2), f32(yy2),
			color.get_gx()
		)
		
		ui.ctx.draw_line(
			f32(xx3), f32(yy3),
			f32(xx4), f32(yy4),
			color.get_gx()
		)
	}
}


pub fn (mut ui UI) draw_rect(from Vec2, size Vec2, config RectConfig) {
	// Draw body
	// IDEA : For lenguage : n-Dimensional match cases
	from2 := from + Vec2.v(config.inset)
	size2 := size - Vec2.v(config.inset * 2.0)
	match config.fill_type {
		.full {
			if config.radius > 0.0 {
				ui.ctx.draw_rounded_rect_filled(
					f32(from2.x), f32(from2.y),
					f32(size2.x), f32(size2.y),
					f32(config.radius - config.inset),
					config.fill_color.get_gx()
				)
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
				ui.draw_rounded_striped_rect(from2, size2, config.radius - config.inset, config.fill_color)
			} else {
				ui.draw_striped_rect(from2, size2, config.fill_color)
			}
		}
		.double {
			if config.radius > 0.0 {
				ui.draw_rounded_double_striped_rect(from2, size2, config.radius - config.inset, config.fill_color)
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
				ui.ctx.draw_rounded_rect_empty(
					f32(from2.x - o), f32(from2.y - o),
					f32(size2.x + o * 2.0), f32(size2.y + o * 2.0),
					f32(config.radius + o - config.inset),
					config.outline_color.get_gx()
				)
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
