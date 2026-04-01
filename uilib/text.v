module uilib

@[params]
pub struct TrimConfig {
	pub mut:
	delimiter_charset           string            = " -"   // If the delimiter_charset is not "", the text can only be trimmed at any of the given charecters in the char set
	continuation                string            = "..."  // Text, that is trimmed away is replaces with the continuation: "This is a very long text" -> "This is..."
	trim_delimiter              bool                       // If true and a delimiter charecter set is set, trimming will occur before the matching delimiter, not after
	
	// Text Style Config
	font_size                   int               = 16
	font_family                 string
}

// Turns "This is a very long long text" with trim_text() and a continuation of "..." into "This is a very..."
pub fn (mut ui UI) trim_text(text string, max_width f64, config TrimConfig) string {
	// Setup text styling
	ui.ctx.set_text_cfg(
		size: config.font_size
		family: config.font_family
	)
	
	// Loop through every charecter, add that to the total string and check, if it is to wide
	mut s := ""
	mut intermediate := ""
	for i, c8 in text {
		c := c8.ascii_str()
		intermediate += c
		total := s + intermediate + config.continuation
		width := ui.ctx.text_width(total)
		if width > max_width {
			if i == 0 {
				return ""
			}
			if config.trim_delimiter {
				return s.trim_right(config.delimiter_charset) + config.continuation
			}
			return s + config.continuation
		}
		if config.delimiter_charset.contains(c) {
			s += intermediate
			intermediate = ""
		}
	}
	return text
}
