module uilib

import std { Color }

pub struct Style {
	pub mut:
	// Colors
	color_bg                   Color               = Color.hex("#121212")
	color_grey                 Color               = Color.hex("#31303b")
	color_text                 Color               = Color.hex("#e3e3dd")
	color_panel                Color               = Color.hex("#232329")
	color_contrast             Color               = Color.hex("#363541")
	
	color_error                Color               = Color.hex("#ff8383")
	color_correct              Color               = Color.hex("#3a994c")
	color_warning              Color               = Color.hex("#f17633")
	color_info                 Color               = Color.hex("#56a2e8")
	
	color_primary_bright       Color               = Color.hex("#bbb8ff")
	color_primary              Color               = Color.hex("#b2aeff")
	color_primary_dark         Color               = Color.hex("#403e6a")
	
	color_instrument           Color               = Color.hex("#31a783")
	color_pattern              Color               = Color.hex("#56a2e8")
	color_effect               Color               = Color.hex("#b594ff")
	color_sound                Color               = Color.hex("#f17633")
	
	color_note_white           Color               = Color.hex("#d3d3d3")
	color_note_black           Color               = Color.hex("#221c19")
	
	colors_users               []Color             = [
		Color.hex("#6e757c"), Color.hex("#a98d84"),
		Color.hex("#3da5b6"), Color.hex("#56a2e8"),
		Color.hex("#b595ff"), Color.hex("#e28af8"),
		Color.hex("#ff8dbc"), Color.hex("#39994b"),
		Color.hex("#32a783"), Color.hex("#b86200"),
		Color.hex("#f17634"), Color.hex("#ff8383"),
	]
	
	// Constants
	padding                    f64                 = 4.0
	strong_padding             f64                 = 12.0
	list_gap                   f64                 = 4.0
	line_spacing               f64                 = 8.0
	seperator_height           f64                 = 10.0
	margin                     f64                 = 6.0
	rounding                   f64                 = 4.0
	outline_size               f64                 = 2.0
	font_size                  int                 = 20
	font_size_title            int                 = 21
	rect_stripe_spacing        f64                 = 8.0
	scroll_speed               f64                 = 12.0
	pan_speed                  f64                 = 1.0
	
	// UX
	scroll_step_v              f64                 = 40.0
	scroll_step_h              f64                 = 40.0
	
	// Fonts
	font_regular               string              = "${@VMODROOT}/uilib/fonts/PlayPenSans-Regular.ttf"
	font_bold                  string              = "${@VMODROOT}/uilib/fonts/PlayPenSans-Bold.ttf"
	font_italic                string              = "${@VMODROOT}/uilib/fonts/PlayPenSans-Regular.ttf" // TODO : Replace with proper italic font
	font_bold_italic           string              = "${@VMODROOT}/uilib/fonts/PlayPenSans-Bold.ttf" // TODO : Replace with proper italic-bold font
	font_mono                  string              = "${@VMODROOT}/uilib/fonts/SourceCodePro-Regular.ttf"
}

