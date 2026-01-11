module geom3

import math

/* TODO :

operators        + - * /
constructors    (x, y, z) scale

length() f64                                       // Returns the length of the vector > basically it's distance from 0,0,0
normalized() Vec3                                  // Normalizes the vector to have a length of 1.0
rescaled(f64 scale) Vec3                           // Rescales the vector to set it's length to a specific given scale, without affecting the direction > basically setting the length
direction_to(Vec3 b) Vec3                          // Returns the normalized direction between two 3D Vectors
distance_to(Vec3 b) f64                            // Returns the distance bewteen two vectors
to_grid(gridx f64, gridy f64, gridz f64) Vec3      // Snaps each of the xyz components of the vector to the grid's size using 'floor' > closes lower number
bounce(Vec3 normal)                                // Takes the current vector and refrlects it back, along an imaginary Plane with the given normal

static : 
dot(Vec3 a, Vec3 b) f64                            // Returns the non-normalized dot product between two vectors

vec_to_ll(Vec3 v) Vec2                             // Converts a directional vector into longditude and latitude
ll_to_vec(Vec2 ll) Vec3                            // Converts a 2D Vec of longditude and latitude to a directional Vec3
cross

*/


// --- STRUCT ---
pub struct Vec3 {
	pub mut:
	x f64
	y f64
	z f64
}

// TODO : Custom constructors, making it possible to only input 1 number, acting as scale for x, y and z.


// --- OPERATORS ---
pub fn (a Vec3) + (b Vec3) Vec3 {
	return Vec3{a.x + b.x, a.y + b.y, a.z + b.z}
}
pub fn (a Vec3) - (b Vec3) Vec3 {
	return Vec3{a.x - b.x, a.y - b.y, a.z - b.z}
}
pub fn (a Vec3) * (b Vec3) Vec3 {
	return Vec3{a.x * b.x, a.y * b.y, a.z * b.z}
}
pub fn (a Vec3) / (b Vec3) Vec3 {
	return Vec3{a.x / b.x, a.y / b.y, a.z / b.z}
}

pub fn (a Vec3) % (b Vec3) Vec3 {
	return Vec3{math.fmod(a.x, b.x), math.fmod(a.y, b.y), math.fmod(a.z, b.z)}
}
pub fn (a Vec3) == (b Vec3) bool {
	return ( a.x == b.x ) && ( a.y == b.y ) && ( a.z == b.z )
}
pub fn (a Vec3) < (b Vec3) bool {
	return ( a.x < b.x ) && ( a.y < b.y ) && ( a.z < b.z )
}


// --- GENERAL ---
pub fn (v Vec3) str() string {
	return "(${v.x}, ${v.y}, ${v.z})"
}

// --- IMPLEMENTED ---
pub fn (v Vec3) length() f64 {
	return math.sqrt( v.x * v.x + v.y * v.y + v.z * v.z )
}

pub fn (v Vec3) normalized() Vec3 {
	l := v.length()
	return Vec3{ v.x / l, v.y / l, v.z / l }
}

/*
pub fn (v Vec3) scaled(scale f64) Vec3 {
	f64 c := math.sqrt( 2.0 * math.pow(0.5 * scale, 2) )
	return v.normalized() * Vec2{c, c}
}
*/

pub fn (a Vec3) direction_to(b Vec3) Vec3 {
	return (b - a).normalized()
}

pub fn (a Vec3) distance_to(b Vec3) f64 {
	return (b - a).length()
}

pub fn (v Vec3) to_grid(gridx f64, gridy f64, gridz f64) Vec3 {
	return Vec3{ math.floor(v.x / gridx) * gridx , math.floor(v.y / gridy) * gridy , math.floor(v.z / gridz) * gridz }
}

pub fn (v Vec3) rotated(axis Vec3, angle f64) Vec3 {
	return Vec3.lerp( Vec3.v( Vec3.dot(axis, v) ) * axis, v, math.cos(angle) ) + Vec3.cross(axis, v) * Vec3.v( math.sin(angle) )
}

pub fn (v Vec3) reflect(n Vec3) Vec3 {
	nn := n.normalized()
	d := Vec3.dot(v, nn)
	
	b := Vec3.v(2.0 * d) * nn
	return v - b
}

pub fn (v Vec3) get_lat() f64 {
	r := v.length()
	return math.asin(v.y / r)
}

pub fn (v Vec3) get_lon() f64 {
	return math.atan2(v.z, v.x)
}

pub fn (v Vec3) pitch(rot f64) Vec3 {
	r := v.length()
	if r == 0 { return Vec3{} }
	lat := math.asin(v.y / r) + rot
	lon := math.atan2(v.z, v.x)
	
	return Vec3{
		x: r * math.cos(lat) * math.cos(lon)
		y: r * math.sin(lat)
		z: r * math.cos(lat) * math.sin(lon)
	}
}

pub fn (v Vec3) pitch_clamped(rot f64, min f64, max f64) Vec3 {
	r := v.length()
	if r == 0 { return Vec3{} }
	mut lat := math.asin(v.y / r) + rot
	lon := math.atan2(v.z, v.x)
	
	if lat < min { lat = min }
	if lat > max { lat = max }
	
	return Vec3{
		x: r * math.cos(lat) * math.cos(lon)
		y: r * math.sin(lat)
		z: r * math.cos(lat) * math.sin(lon)
	}
}

pub fn (v Vec3) yaw(rot f64) Vec3 {
	r := v.length()
	if r == 0 { return Vec3{} }
	lat := math.asin(v.y / r)
	lon := math.atan2(v.z, v.x) + rot
	
	return Vec3{
		x: r * math.cos(lat) * math.cos(lon)
		y: r * math.sin(lat)
		z: r * math.cos(lat) * math.sin(lon)
	}
}


pub fn (v Vec3) backward() Vec3 {
	return Vec3{0, 0, 0} - v
}

pub fn (v Vec3) right() Vec3 {
	up := Vec3{0, 1, 0}
	return Vec3{0, 0, 0} - Vec3.cross(v, up)
}

pub fn (v Vec3) left() Vec3 {
	up := Vec3{0, 1, 0}
	return Vec3.cross(v, up)
}

pub fn (v Vec3) down() Vec3 {
	right := v.right()
	return Vec3.cross(v, right)
}

pub fn (v Vec3) up() Vec3 {
	right := v.right()
	return Vec3{0, 0, 0} - Vec3.cross(v, right)
}


// --- STATIC ---
pub fn Vec3.v(s f64) Vec3 {
	return Vec3{s, s, s}
}

pub fn Vec3.dot(a Vec3, b Vec3) f64 {
	return a.x * b.x + a.y * b.y + a.z * b.z
}

pub fn Vec3.cross(a Vec3, b Vec3) Vec3 {
	return Vec3{
		x: a.y * b.z  -  a.z * b.y
		y: a.z * b.x  -  a.x * b.z
		z: a.x * b.y  -  a.y * b.x
	}
}

pub fn Vec3.lerp(a Vec3, b Vec3, t f64) Vec3 {
	return Vec3{
		x: a.x + (b.x - a.x) * t
		y: a.y + (b.y - a.y) * t
		z: a.z + (b.z - a.z) * t
	}
}

// --- UTIL ---

pub fn Vec3.zero() Vec3     { return Vec3{0, 0, 0} }
pub fn Vec3.one() Vec3      { return Vec3{1, 1, 1} }

pub fn Vec3.value(x f64) Vec3 {
	return Vec3{x, x, x}
}

