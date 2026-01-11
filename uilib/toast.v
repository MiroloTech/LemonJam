module uilib

import gg
import std.geom2 { Vec2 }
import std { Color }
import std.visual

pub enum ToastMessageType {
	hint       // grey dot
	info       // blue dot
	warning    // yeloow triangle
	error      // red octagon
}

const toast_animation_time := 0.4
const toast_height := 30.0

pub struct ToastStyle {
	pub mut:
	height          f64                     = toast_height
	width           f64                     = 400.0
	spacing         f64                     = 80.0
	rounding        f64                     = 6.0
	text_size       int                     = 18
	part_padding    f64                     = 15.0
	line_width      f64                     = 3.0
	icon_size       f64                     = 6.0
	
	text_color      Color                   = Color.hex("#dddddd")
	bg_color        Color                   = Color.hex("#333333cc")
	count_color     Color                   = Color.hex("#888888")
	
	color_hint      Color                   = Color.hex("#dddddd")
	color_info      Color                   = Color.hex("#00a2e8")
	color_warning   Color                   = Color.hex("#ffe176")
	color_error     Color                   = Color.hex("#ed1c24")
	
	font_path       string                  = "${@VMODROOT}/graph/assets/SourceCodePro-Medium.ttf"
}

pub struct Toast {
	pub mut:
	msg             string
	typ             ToastMessageType        = .hint
	time            f64                     = 3.0
	lifetime        f64                     = 3.0
	count           int                     = 1
	style           ToastStyle              = ToastStyle{}
}

pub fn (toast Toast) draw(mut ctx gg.Context, pos Vec2, opacity f64) {
	color := match toast.typ {
		.hint      { toast.style.color_hint.alpha(opacity) }
		.info      { toast.style.color_info.alpha(opacity) }
		.warning   { toast.style.color_warning.alpha(opacity) }
		.error     { toast.style.color_error.alpha(opacity) }
	}
	
	// Draw BG
	ctx.draw_rounded_rect_filled(
		f32(pos.x - toast.style.width), f32(pos.y),
		f32(toast.style.width), f32(toast.style.height),
		f32(toast.style.rounding),
		toast.style.bg_color.alpha(opacity).get_gx()
	)
	
	// Draw Side Line
	visual.draw_special_rounded_rect_filled(
		mut ctx,
		f32(pos.x - toast.style.width), f32(pos.y),
		f32(toast.style.line_width), f32(toast.style.height),
		color.get_gx(),
		r1: f32(toast.style.rounding)
		r2: f32(0.0)
		r3: f32(0.0)
		r4: f32(toast.style.rounding)
	)
	
	// Draw Icon
	icon_pos := Vec2{pos.x - toast.style.width + toast.style.line_width + toast.style.part_padding + toast.style.icon_size * 0.5, pos.y + toast.style.height * 0.5}
	match toast.typ {
		.hint      { ctx.draw_polygon_filled(f32(icon_pos.x), f32(icon_pos.y), f32(toast.style.icon_size), 24, f32(0.0), color.get_gx()) }
		.info      { ctx.draw_polygon_filled(f32(icon_pos.x), f32(icon_pos.y), f32(toast.style.icon_size), 24, f32(0.0), color.get_gx()) }
		.warning   { ctx.draw_polygon_filled(f32(icon_pos.x), f32(icon_pos.y), f32(toast.style.icon_size), 3,  f32(30), color.get_gx()) }
		.error     { ctx.draw_polygon_filled(f32(icon_pos.x), f32(icon_pos.y), f32(toast.style.icon_size), 6,  f32(0.3926991), color.get_gx()) }
	}
	
	// Draw Text
	ctx.set_text_cfg(
		color:           toast.style.text_color.alpha(opacity).get_gx()
		family:          toast.style.font_path
		size:            toast.style.text_size
		vertical_align:  .middle
		align:           .left
	)
	
	text_pos := Vec2{pos.x - toast.style.width + toast.style.line_width + toast.style.icon_size + toast.style.part_padding * 2.0, pos.y + toast.style.height * 0.5}
	if toast.count == 1 {
		for i, line in toast.msg.split("\n") {
			ctx.draw_text_default(
				int(text_pos.x), int(text_pos.y + f64(i) * toast.style.height),
				line
			)
		}
	} else {
		count_text := "${toast.count}x "
		for i, line in toast.msg.split("\n") {
			ctx.draw_text_default(
				int(text_pos.x + ctx.text_width(count_text)), int(text_pos.y + f64(i) * toast.style.height),
				line
			)
		}
		
		ctx.set_text_cfg(
			color:           toast.style.count_color.alpha(opacity).get_gx()
			family:          toast.style.font_path
			size:            toast.style.text_size
			vertical_align:  .middle
			align:           .left
		)
		ctx.draw_text_default(
			int(text_pos.x), int(text_pos.y),
			count_text
		)
	}
}

// Adds a toast, or adds to duplicate counter, if the message is already in list of toasts
pub fn (mut toasts []Toast) add_toast(msg string, typ ToastMessageType, lifetime f64, custom_style ToastStyle) {
	for mut toast in toasts {
		if toast.msg == msg && toast.time > 0.0 {
			toast.time = toast.lifetime
			toast.count += 1
			return
		}
	}
	lines := msg.count("\n") + 1
	toasts << Toast{
		msg: msg
		typ: typ
		lifetime: lifetime
		time: lifetime
		style: ToastStyle{
			...custom_style
			height: custom_style.height * f64(lines)
		}
	}
}

// Sorts the toasts, so the 
pub fn (mut toasts []Toast) sort_by_time() {
	toasts.sort(a.time > b.time)
}

// Updates the time on every toast, and removes the ones, that are timed out
pub fn (mut toasts []Toast) update(delta f64) {
	for i in 0..toasts.len {
		ii := toasts.len - i - 1
		toasts[ii].time -= delta
		if toasts[ii].time < -toast_animation_time {
			toasts.delete(ii)
		}
	}
}

pub fn (mut toasts []Toast) draw(mut ctx gg.Context, start_corner Vec2, spacing f64) {
	if toasts.len == 0 { return }
	
	// Keep track of the total y of each toast
	mut y := start_corner.y - toasts[0].style.height
	
	for toast in toasts {
		// > Check, if any Toast has a time less than toast_animation_time, and if true, move up every other toast by the toast height off factored by the pop-in progress
		mut f := 1.0 - ((toast.time - (toast.lifetime - toast_animation_time)) / toast_animation_time)
		if toast.count > 1.0 { f = 1.0 }
		if 0.0 <= f && f < 1.0 {
			f = anim_in_ease(f)
			y -= f * (toast.style.height + spacing)
			toast.draw(mut ctx, Vec2{start_corner.x, y + (1.0 - f) * 40.0}, f)
		}
		else if toast.time <= 0.0 {
			f = (-toast.time / toast_animation_time)
			y -= (1.0 - f) * toast.style.height + spacing
			toast.draw(mut ctx, Vec2{start_corner.x, y - f * 80.0}, 1.0 - f)
		}
		else {
			y -= toast.style.height + spacing
			toast.draw(mut ctx, Vec2{start_corner.x, y}, 1.0)
		}
	}
}

fn anim_in_ease(x f64) f64 {
	return 1.0 - ((1.0 - x) * (1.0 - x) * (1.0 - x))
}

pub struct Toaster {
	pub mut:
	from           Vec2
	size           Vec2
	spacing        f64                     = 20.0
	style          ToastStyle              = ToastStyle{}
	toasts         []Toast                 = []Toast{}
}

pub fn (mut toaster Toaster) draw(mut ui UI) {
	toaster.toasts.draw(mut ui.ctx, toaster.from, toaster.spacing)
	toaster.toasts.update(ui.delta)
	toaster.style = ToastStyle{
		height:                                toaster.size.y
		width:                                 toaster.size.x
		spacing:                               80.0
		rounding:                              ui.style.rounding
		text_size:                             ui.style.font_size
		part_padding:                          15.0
		line_width:                            3.0
		icon_size:                             6.0
		
		text_color:                            ui.style.color_text
		bg_color:                              ui.style.color_bg.brighten(0.1)
		count_color:                           ui.style.color_grey.brighten(0.2)
		
		color_hint:                            ui.style.color_grey
		color_info:                            ui.style.color_info
		color_warning:                         ui.style.color_warning
		color_error:                           ui.style.color_error
		
		font_path:                             ui.style.font_mono
	}
}


pub fn (mut toaster Toaster) add_toast(msg string, typ ToastMessageType, lifetime f64) {
	toaster.toasts.add_toast(msg, typ, lifetime, toaster.style)
}