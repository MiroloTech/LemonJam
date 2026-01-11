module visual

import stbi

import std { Color }

pub enum ColorSpace {
	black_white         // Black or White : 1 bit per pixel
	l8                  // Luminance : 8 bpp
	la8                 // Luminance and Alpha : 16 bpp
	r8                  // Red : 8 bpp
	rg8                 // Red & Green : 16 bpp
	rgb8                // Red, Green & Blue : 24 bpp
	rgba8               // Red, Green, Blue & Alpha : 32 bpp
}

pub struct Image {
	pub mut:
	buffer          &u8                = unsafe { nil }
	size            u64
	
	width           int
	height          int
	color_space     ColorSpace
}



// Image.create_from_file creates an Image from the given path. ( returns an error, if file not found or file can't be interpreted )
// Supported file formats are: .png, .jpg, .bmp, .tga
pub fn Image.create_from_file(path string) !Image {
	stbi_image := stbi.load(path) or { return error("Can't load file from path '${path}' : ${err}") }
	color_space := match stbi_image.nr_channels {
		1 { ColorSpace.r8 }
		2 { ColorSpace.rg8 }
		3 { ColorSpace.rgb8 }
		4 { ColorSpace.rgba8 }
		else { ColorSpace.l8 }
	}
	return Image{
		buffer: stbi_image.data
		size: u64(stbi_image.width) * u64(stbi_image.height) * u64(stbi_image.nr_channels)
		width: stbi_image.width
		height: stbi_image.height
		color_space: color_space
	}
}

// Image.create_empty creates a zeroed Image with given settings
pub fn Image.create_empty(width int, height int, color_space ColorSpace) Image {
	size := get_buff_size_for_color_space(color_space, u64(width * height))
	mut buff := vcalloc(size)
	mut img := Image{
		size:         size
		buffer:       buff
		width:        width
		height:       height
		color_space:  color_space
	}
	return img
}


// fill set's each pixel in the image to the given color
pub fn (mut img Image) fill(color Color) {
	for i in 0..(img.width * img.height) {
		bytes := color2bytes(color, img.color_space)
		for boff, byt in bytes {
			// > Exception for black_white color space
			if img.color_space == .black_white {
				bit_offset := i % 8
				unsafe { img.buffer[i / 8] = img.buffer[i / 8] | byt << bit_offset }
			}
			else {
				unsafe { img.buffer[i + boff] = byt }
			}
		}
	}
}

pub fn (img Image) get_pixel(x int, y int) Color {
	mut xx := if x < 0 { 0 } else { if x >= img.width { img.width - 1 } else { x } }
	mut yy := if y < 0 { 0 } else { if y >= img.height { img.height - 1 } else { y } }
	
	byte_size := color2bytes(Color{}, img.color_space).len
	i := (yy * img.width + xx) * byte_size
	bit_offset := (yy * img.width + xx) % 8
	mut bytes := []u8{}
	for step in 0..get_buff_size_for_color_space(img.color_space, u64(1)) {
		bytes << unsafe { img.buffer[i + int(step)] }
	}
	
	if img.color_space == .black_white {
		mut b := bytes[0]
		b >> bit_offset
		b = b | u8(1)
		return bytes2color([b], img.color_space)
	}
	
	return bytes2color(bytes, img.color_space)
}


// aspect_ratio returns the x scaling factor of the image's y dimenson (x / y)
pub fn (img Image) aspect_ratio() f64 {
	return f64(img.width) / f64(img.height)
}


// ===== UTILLITY =====

// get_buff_size_for_color_space returns the neccessarry byte size in memory to store an image of given 'pixel_count' and 'color_space'
fn get_buff_size_for_color_space(color_space ColorSpace, pixel_count u64) u64 {
	if pixel_count <= 0 { return u64(0) }
	
	match color_space {
		.l8, .r8        { return pixel_count }
		.la8,  .rg8     { return pixel_count * 2 }
		.rgb8           { return pixel_count * 3 }
		.rgba8          { return pixel_count * 4 }
		.black_white    { return (if pixel_count % u64(8) == 0 { pixel_count / u64(8) } else { pixel_count / u64(8) + u64(1) }) }
	}
}


// color2bytes takes in a color and a respective color space and returns the byte structure in an array of bytes
// Note: a 'black_white' color space has to be manually shifted, since the byte returned is either 1 or 0
fn color2bytes(color Color, color_space ColorSpace) []u8 {
	match color_space {
		.l8             { return [u8(color.value() * 255.0)] }
		.la8            { return [u8(color.value() * 255.0), u8(color.a * 255.0)] }
		.r8             { return [u8(color.r * 255.0)] }
		.rg8            { return [u8(color.r * 255.0), u8(color.g * 255.0)] }
		.rgb8           { return [u8(color.r * 255.0), u8(color.g * 255.0), u8(color.b * 255.0)] }
		.rgba8          { return [u8(color.r * 255.0), u8(color.g * 255.0), u8(color.b * 255.0), u8(color.a * 255.0)] }
		.black_white    { return [(if color.value() >= 0.5 { u8(1) } else { u8(0) })] }
	}
}

fn bytes2color(bytes []u8, color_space ColorSpace) Color {
	match color_space {
		.l8             { return Color{f64(bytes[0]) / 255.0, f64(bytes[0]) / 255.0, f64(bytes[0]) / 255.0, 1.0} }
		.la8            { return Color{f64(bytes[0]) / 255.0, f64(bytes[0]) / 255.0, f64(bytes[0]) / 255.0, f64(bytes[1]) / 255.0} }
		.r8             { return Color{f64(bytes[0]) / 255.0, 0.0,                   0.0,                   1.0} }
		.rg8            { return Color{f64(bytes[0]) / 255.0, f64(bytes[1]) / 255.0, 0.0,                   1.0} }
		.rgb8           { return Color{f64(bytes[0]) / 255.0, f64(bytes[1]) / 255.0, f64(bytes[2]) / 255.0, 1.0} }
		.rgba8          { return Color{f64(bytes[0]) / 255.0, f64(bytes[1]) / 255.0, f64(bytes[2]) / 255.0, f64(bytes[3]) / 255.0} }
		.black_white    { return Color{f64(bytes[0]),         f64(bytes[0]),         f64(bytes[0]),         1.0} }
	}
}
