module visual

import gg
import math { clamp, min }

import std.geom2 { Vec2 }
import std { Color }

type StringColChar = Color | string
type StringCol = []StringColChar

const rad0   := 0.0
const rad90  := 1.57079632679
const rad180 := 3.14159265359
const rad270 := 4.71238898038
const rad360 := 6.28318530718


pub fn draw_image(mut ctx gg.Context, img Image, x int, y int, width int, height int, img_cfg ImageDrawCfg) {
	// TODO : Optimize Image drawing function
	for xx in x..(x + width) {
		for yy in y..(y + height) {
			// TODO : Add antialiasing
			x_fract := f64(xx - x) / f64(width)
			y_fract := f64(yy - y) / f64(height)
			x_img := int(x_fract * img.width)
			y_img := int(y_fract * img.height)
			
			col := img.get_pixel(x_img, y_img)
			if col.a <= img_cfg.threshhold { continue }
			
			ctx.draw_pixel(xx, yy, col.get_gx())
		}
	}
}

// draw_icon is a specialized function to draw_image, which draws the image with an alpha cut value of 0.5 and a custom fill value
pub fn draw_icon(mut ctx gg.Context, img Image, x int, y int, width int, height int, fill_color Color) {
	// TODO : Optimize Image drawing function
	for xx in x..(x + width) {
		for yy in y..(y + height) {
			// TODO : Add antialiasing
			x_fract := f64(xx - x) / f64(width)
			y_fract := f64(yy - y) / f64(height)
			x_img := int(x_fract * img.width)
			y_img := int(y_fract * img.height)
			
			col := img.get_pixel(x_img, y_img)
			if col.a < 0.5 { continue }
			
			ctx.draw_pixel(xx, yy, fill_color.get_gx())
		}
	}
}

// draw_text_fancy allows you to easily draw text with specific font, coloring and styling options. This is meant to replace the hassle of regularly drawing multi-color and font-specific text
pub fn draw_text_fancy(mut ctx gg.Context, text StringCol, x int, y int, cfg TextCfg) {
	mut currx := 0
	for token in text {
		if token is Color {
			ctx.set_text_cfg(
				color:   token.get_gx()
				size:    cfg.size
				family:  cfg.font_path
				bold:    cfg.bold
				mono:    cfg.mono
				italic:  cfg.italic
			)
		}
		if token is string {
			ctx.draw_text_default(currx + x, y, token)
			currx += ctx.text_width(token)
		}
	}
}

pub fn draw_thick_line(mut ctx gg.Context, ax f32, ay f32, bx f32, by f32, width f32, color gg.Color) {
	mut tangent := Vec2{ax, ay}.direction_to(Vec2{bx, by})
	tangent = Vec2{tangent.y, -tangent.x} * Vec2{width * 0.5, width * 0.5}
	ctx.draw_line_with_config(
		ax + f32(tangent.x), ay + f32(tangent.y),
		bx + f32(tangent.x), by + f32(tangent.y),
		color: color
		thickness: width
	)
}


pub fn draw_special_rounded_rect_filled(mut ctx gg.Context, x f32, y f32, w f32, h f32, c gg.Color, rounding RectRounding) {
	// Corners
	segments := rounding.segments
	
	r1 := f32(clamp(rounding.r1 or { rounding.radius }, 0.0, min(f64(w), f64(h)) / 2.0))
	r2 := f32(clamp(rounding.r2 or { rounding.radius }, 0.0, min(f64(w), f64(h)) / 2.0))
	r3 := f32(clamp(rounding.r3 or { rounding.radius }, 0.0, min(f64(w), f64(h)) / 2.0))
	r4 := f32(clamp(rounding.r4 or { rounding.radius }, 0.0, min(f64(w), f64(h)) / 2.0))
	
	// > Top Left
	ctx.draw_slice_filled(
		x + r1, y + r1,
		r1,
		f32(rad180), f32(rad270),
		segments, c
	)
	
	// > Top Right
	ctx.draw_slice_filled(
		x + w - r2, y + r2,
		r2,
		f32(rad90), f32(rad180),
		segments, c
	)
	
	// > Bottom Right
	ctx.draw_slice_filled(
		x + w - r4, y + h - r4,
		r4,
		f32(rad0), f32(rad90),
		segments, c
	)
	
	// > Bottom Left
	ctx.draw_slice_filled(
		x + r3, y + h - r3,
		r3,
		f32(rad270), f32(rad360),
		segments, c
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
		[x + w, y + h - r3],
		[x + w - r3, y + h - r3],
		[x + w - r3, y + h],
	]
	
	pts << [ // Bottom Left
		[x + r4, y + h],
		[x + r4, y + h - r4],
		[x, y + h - r4],
	]
	
	ctx.draw_triangle_filled(
		pts[1][0], pts[1][1],
		pts[2][0], pts[2][1],
		pts[3][0], pts[3][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[3][0], pts[3][1],
		pts[4][0], pts[4][1],
		pts[1][0], pts[1][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[4][0], pts[4][1],
		pts[5][0], pts[5][1],
		pts[6][0], pts[6][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[6][0], pts[6][1],
		pts[7][0], pts[7][1],
		pts[4][0], pts[4][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[7][0], pts[7][1],
		pts[8][0], pts[8][1],
		pts[9][0], pts[9][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[9][0], pts[9][1],
		pts[10][0], pts[10][1],
		pts[7][0], pts[7][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[10][0], pts[10][1],
		pts[11][0], pts[11][1],
		pts[0][0], pts[0][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[0][0], pts[0][1],
		pts[1][0], pts[1][1],
		pts[10][0], pts[10][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[1][0], pts[1][1],
		pts[4][0], pts[4][1],
		pts[7][0], pts[7][1],
		c
	)
	ctx.draw_triangle_filled(
		pts[7][0], pts[7][1],
		pts[10][0], pts[10][1],
		pts[1][0], pts[1][1],
		c
	)
}

pub fn draw_thick_bezier(mut ctx gg.Context, ax f64, ay f64, bx f64, by f64, cx f64, cy f64, dx f64, dy f64, witdh f64, cola Color, colb Color, segments int) {
	a := Vec2{ax, ay}
	b := Vec2{bx, by}
	c := Vec2{cx, cy}
	d := Vec2{dx, dy}
	
	mut last_point := a
	mut last_tangent := Vec2{0.0, -1.0}
	
	for seg in 0..segments {
		t := f64(seg + 1) / f64(segments)
		
		// > Lerp bezier Curve
		e := Vec2.lerp(a, b, t)
		f := Vec2.lerp(b, c, t)
		g := Vec2.lerp(c, d, t)
		
		h := Vec2.lerp(e, f, t)
		i := Vec2.lerp(f, g, t)
		j := Vec2.lerp(h, i, t)
		
		mut tangent := last_point.direction_to(j)
		tangent = Vec2{tangent.y, -tangent.x}
		
		// > Draw segment
		color := Color.lerp(cola, colb, t).get_gx()
		
		tria := last_point    - last_tangent * Vec2.v(witdh * 0.5)
		trib := j             - tangent      * Vec2.v(witdh * 0.5)
		tric := j             + tangent      * Vec2.v(witdh * 0.5)
		trid := last_point    + last_tangent * Vec2.v(witdh * 0.5)
		
		ctx.draw_triangle_filled(
			f32(tria.x), f32(tria.y),
			f32(trib.x), f32(trib.y),
			f32(tric.x), f32(tric.y),
			color
		)
		ctx.draw_triangle_filled(
			f32(tric.x), f32(tric.y),
			f32(trid.x), f32(trid.y),
			f32(tria.x), f32(tria.y),
			color
		)
		
		last_point = j
		last_tangent = tangent
	}
}


@[params]
pub struct RectRounding {
	pub:
	r1         ?f32             // Top Left
	r2         ?f32             // Top Right
	r3         ?f32             // Bottom Left
	r4         ?f32             // Bottom Right
	radius     f32              // Base rounding
	segments   int       = 32   // Rounding steps
}

@[params]
pub struct TextCfg {
	pub:
	size                  int
	font_path             string
	bold                  bool
	mono                  bool
	italic                bool
	
	line_spacing          f64
}

@[params]
pub struct ImageDrawCfg {
	pub:
	threshhold          f64          = 0.01        // Threshhold at which drawing the pixel in an image is discarded
}

