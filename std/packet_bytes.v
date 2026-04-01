module std

import encoding.binary
import std.geom2 { Vec2 }
import std.geom3 { Vec3 }

// Utillity script to make reading data from one long byte array easier
// Note: Every pop command is interpreted in big-endian format and pops from left to right

union U32_F32 {
	u u32
	f f32
}

union U64_F64 {
	u u64
	f f64
}

pub type ByteStack = []u8

// ====== POP ======

pub fn (mut bytes ByteStack) pop_u8() u8 {
	return bytes.pop_left()
}

pub fn (mut bytes ByteStack) pop_u16() u16 {
	return binary.big_endian_u16([bytes.pop_left(), bytes.pop_left()])
}

pub fn (mut bytes ByteStack) pop_u32() u32 {
	return binary.big_endian_u32([bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left()])
}

pub fn (mut bytes ByteStack) pop_u64() u64 {
	return binary.big_endian_u64([bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left(), bytes.pop_left()])
}

pub fn (mut bytes ByteStack) pop_i8() i8 {
	return i8(u8(bytes.pop_u8()) + u8(min_i8))
}

pub fn (mut bytes ByteStack) pop_i16() i16 {
	return i16(u16(bytes.pop_u16()) + u16(min_i16))
}

pub fn (mut bytes ByteStack) pop_i32() i32 {
	return i32(u32(bytes.pop_u32()) + u32(min_i32))
}

pub fn (mut bytes ByteStack) pop_int() int {
	return int(bytes.pop_i32())
}

pub fn (mut bytes ByteStack) pop_i64() i64 {
	return i64(u64(bytes.pop_u64()) + u64(min_i64))
}

pub fn (mut bytes ByteStack) pop_bool() bool {
	return bytes.pop_u8() != 0
}

pub fn (mut bytes ByteStack) pop_f32() f32 {
	return unsafe { U32_F32{u: bytes.pop_u32()}.f }
}

pub fn (mut bytes ByteStack) pop_f64() f64 {
	return unsafe { U64_F64{u: bytes.pop_u64()}.f }
}

pub fn (mut bytes ByteStack) pop_string() string {
	return bytes.pop_arr[u8]().bytestr()
}

pub fn (mut bytes ByteStack) pop_color() Color {
	return Color.rgba8( bytes.pop_u8(), bytes.pop_u8(), bytes.pop_u8(), bytes.pop_u8() )
}

pub fn (mut bytes ByteStack) pop_vec2() Vec2 {
	return Vec2{ f64(bytes.pop_f32()), f64(bytes.pop_f32()) }
}

pub fn (mut bytes ByteStack) pop_vec3() Vec3 {
	return Vec3{ f64(bytes.pop_f32()), f64(bytes.pop_f32()), f64(bytes.pop_f32()) }
}

// Note: Type T must be a supported type. Otherwise the length of the array will be popped, and an empty array of the given type with the given length will be returned, but no element will be popped.
pub fn (mut bytes ByteStack) pop_arr[T]() []T {
	len := int_max(int(bytes.pop_u32()), 0)
	println("Length of arr: ${len}")
	mut arr := []T{len: len, init: T{}}
	for i in 0..len {
		$if T is u8     { arr[i] = bytes.pop_u8() }
		$if T is u16    { arr[i] = bytes.pop_u16() }
		$if T is u32    { arr[i] = bytes.pop_u32() }
		$if T is u64    { arr[i] = bytes.pop_u64() }
		$if T is i8     { arr[i] = bytes.pop_i8() }
		$if T is i16    { arr[i] = bytes.pop_i16() }
		$if T is i32    { arr[i] = bytes.pop_i32() }
		$if T is i64    { arr[i] = bytes.pop_i64() }
		$if T is bool   { arr[i] = bytes.pop_bool() }
		$if T is f32    { arr[i] = bytes.pop_f32() }
		$if T is f64    { arr[i] = bytes.pop_f64() }
		$if T is string { arr[i] = bytes.pop_string() }
		$if T is Color  { arr[i] = bytes.pop_color() }
		$if T is Vec2   { arr[i] = bytes.pop_vec2() }
		$if T is Vec3   { arr[i] = bytes.pop_vec3() }
	}
	return arr
}

// ====== PUSH ======

pub fn (mut bytes ByteStack) push_u8(v u8) {
	bytes << v
}

pub fn (mut bytes ByteStack) push_u16(v u16) {
	bytes << binary.big_endian_get_u16(v)
}

pub fn (mut bytes ByteStack) push_u32(v u32) {
	bytes << binary.big_endian_get_u32(v)
}

pub fn (mut bytes ByteStack) push_u64(v u64) {
	bytes << binary.big_endian_get_u64(v)
}

pub fn (mut bytes ByteStack) push_i8(v i8) {
	bytes.push_u8(u8(v) - u8(min_i8))
}

pub fn (mut bytes ByteStack) push_i16(v i16) {
	bytes.push_u16(u16(v) - u16(min_i16))
}

pub fn (mut bytes ByteStack) push_i32(v i32) {
	bytes.push_u32(u32(v) - u32(min_i32))
}

pub fn (mut bytes ByteStack) push_int(v int) {
	bytes.push_i32(int(v))
}

pub fn (mut bytes ByteStack) push_i64(v i64) {
	bytes.push_u64(u64(v) - u64(min_i64))
}

pub fn (mut bytes ByteStack) push_bool(v bool) {
	bytes << u8(v)
}

pub fn (mut bytes ByteStack) push_f32(v f32) {
	bytes.push_u32(unsafe { U32_F32{f: v}.u })
}

pub fn (mut bytes ByteStack) push_f64(v f64) {
	bytes.push_u64(unsafe { U64_F64{f: v}.u })
}

pub fn (mut bytes ByteStack) push_string(v string) {
	bytes.push_arr[u8](v.bytes())
}

pub fn (mut bytes ByteStack) push_color(v Color) {
	r, g, b, a := v.get_rgba8()
	bytes << [r, g, b, a]
}

pub fn (mut bytes ByteStack) push_vec2(v Vec2) {
	bytes.push_f32(f32(v.x))
	bytes.push_f32(f32(v.y))
}

pub fn (mut bytes ByteStack) push_vec3(v Vec3) {
	bytes.push_f32(f32(v.x))
	bytes.push_f32(f32(v.y))
	bytes.push_f32(f32(v.z))
}

// Note: Type T must be a supported type. Otherwise the length of the array will be popped, and an empty array of the given type with the given length will be returned, but no element will be popped.
pub fn (mut bytes ByteStack) push_arr[T](arr []T) {
	len := int(arr.len)
	bytes.push_u32(u32(len))
	for v in arr {
		$if T is u8     { bytes.push_u8(v) }
		$if T is u16    { bytes.push_u16(v) }
		$if T is u32    { bytes.push_u32(v) }
		$if T is u64    { bytes.push_u64(v) }
		$if T is i8     { bytes.push_i8(v) }
		$if T is i16    { bytes.push_i16(v) }
		$if T is i32    { bytes.push_i32(v) }
		$if T is i64    { bytes.push_i64(v) }
		$if T is bool   { bytes.push_bool(v) }
		$if T is f32    { bytes.push_f32(v) }
		$if T is f64    { bytes.push_f64(v) }
		$if T is string { bytes.push_string(v) }
		$if T is Color  { bytes.push_color(v) }
		$if T is Vec2   { bytes.push_vec2(v) }
		$if T is Vec3   { bytes.push_vec3(v) }
	}
}


