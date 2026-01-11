module ease

import math

// https://easings.net

// --- Constant definitions for easing functions ---
const c1 := 1.70158
const c2 := c1 + 1.525
const c3 := c1 + 1.0
const c4 := math.tau / 3.0
const c5 := math.tau / 4.5
const n1 := 7.5625
const d1 := 2.75

pub type EaseFn = fn (x f64) f64

// --- Easing functions ---

pub fn linear(x f64) f64 {
	return x
}

pub fn ease_in_sine(x f64) f64 {
	return 1.0 - math.cos( (x * math.pi) / 2.0 )
}

pub fn ease_out_sine(x f64) f64 {
	return math.sin( (x * math.pi) / 2.0 )
}

pub fn ease_inout_sine(x f64) f64 {
	return -( math.cos( math.pi * x ) - 1.0 ) / 2.0
}


pub fn ease_in_quad(x f64) f64 {
	return x * x
}

pub fn ease_out_quad(x f64) f64 {
	return 1.0 - (1.0 - x) * (1.0 - x)
}

pub fn ease_inout_quad(x f64) f64 {
	return if x < 0.5  { 2 * x * x }  else  { 1.0 - math.pow( -2.0 * x + 2.0, 2.0 ) / 2.0 }
}


pub fn ease_in_cubic(x f64) f64 {
	return x * x * x
}

pub fn ease_out_cubic(x f64) f64 {
	return 1.0 - math.pow(1.0 - x, 3.0)
}

pub fn ease_inout_cubic(x f64) f64 {
	return if x < 0.5  { 4.0 * x * x * x }  else  { 1.0 - math.pow( -2.0 * x + 2.0, 3.0 ) / 2.0 }
}


pub fn ease_in_quart(x f64) f64 {
	return x * x * x * x
}

pub fn ease_out_quart(x f64) f64 {
	return 1.0 - math.pow( 1.0 - x, 4.0 )
}

pub fn ease_inout_quart(x f64) f64 {
	return if x < 0.5  { 8.0 * x * x * x * x }  else  { 1.0 - math.pow( -2.0 * x + 2.0, 4.0 ) / 2.0 }
}


pub fn ease_in_quint(x f64) f64 {
	return x * x * x * x * x
}

pub fn ease_out_quint(x f64) f64 {
	return 1.0 - math.pow( 1.0 - x, 5.0 )
}

pub fn ease_inout_quint(x f64) f64 {
	return if x < 0.5  { 16.0 * x * x * x * x * x }  else  { 1.0 - math.pow( -2.0 * x + 2.0, 5.0 ) / 2.0 }
}


pub fn ease_in_expo(x f64) f64 {
	return if x == 0.0  { 0.0 }  else  { math.pow( 2.0, 10.0 * x - 10.0 ) }
}

pub fn ease_out_expo(x f64) f64 {
	return if x == 1.0  { 1.0 }  else  { 1.0 - math.pow( 2.0, -10.0 * x ) }
}

pub fn ease_inout_expo(x f64) f64 {
	if x == 0.0 { return 0.0 }
	if x == 1.0 { return 1.0 }
	return if x < 0.5  { math.pow( 2.0, 20.0 * x - 10.0 ) / 2.0 }  else  { (2.0 - math.pow(2.0, -20.0 * x + 10.0)) / 2.0 }
}


pub fn ease_in_circ(x f64) f64 {
	return 1.0 - math.sqrt( 1.0 - ( x * x ) )
}

pub fn ease_out_circ(x f64) f64 {
	return math.sqrt( 1.0 - math.pow( x - 1.0, 2.0) )
}

pub fn ease_inout_circ(x f64) f64 {
	return if x < 0.5  { (1.0 - math.sqrt( 1.0 - 2.0*x * 2.0*x )) / 2.0 }  else  { (math.sqrt( 1.0 - math.pow( -2.0 * x + 2.0, 2.0 ) ) + 1) / 2.0 }
}


pub fn ease_in_back(x f64) f64 {
	return c3 * x * x * x - c1 * x * x
}

pub fn ease_out_back(x f64) f64 {
	return 1.0 + c3 * math.pow(x - 1.0, 3.0) + c1 * math.pow(x - 1.0, 2.0)
}

pub fn ease_inout_back(x f64) f64 {
	return if x < 0.5  { (math.pow(2.0 * x, 2.0) * ((c2 + 1.0) * 2.0 * x - c2)) / 2.0 }  else  { (math.pow(2.0 * x - 2.0, 2.0) * ((c2 + 1.0) * (x * 2.0 - 2.0) + c2) + c2) / 2.0 }
}


pub fn ease_in_elastic(x f64) f64 {
	if x == 0.0 { return 0.0 }
	if x == 1.0 { return 1.0 }
	return -math.pow( 2.0, 10.0 * x - 10.0 ) * math.sin( (x * 10.0 - 10.75) * c4 )
}

pub fn ease_out_elastic(x f64) f64 {
	if x == 0.0 { return 0.0 }
	if x == 1.0 { return 1.0 }
	return math.pow( 2.0, -10.0 * x ) * math.sin( (x * 10.0 - 0.75) * c4 ) + 1.0
}

pub fn ease_inout_elastic(x f64) f64 {
	if x == 0.0 { return 0.0 }
	if x == 1.0 { return 1.0 }
	return if x < 0.5  { -( math.pow(2.0, 20.0 * x - 10.0) * math.sin( (20.0 * x - 11.125) * c5 ) ) / 2.0 }  else  { ( math.pow(2.0, -20.0 * x + 10.0) * math.sin( (20.0 * x - 11.125) * c5 ) ) / 2.0 + 1.0 }
}


pub fn ease_in_bounce(x f64) f64 {
	return 1.0 - ease_out_bounce(1.0 - x)
}

pub fn ease_out_bounce(x f64) f64 {
	if x < 1.0 / d1 {
		return n1 * x * x
	} else if x < 2.0 / d1 {
		v := x - 1.5 / d1
		return n1 * v * v + 0.75
	} else if x < 2.25 / d1 {
		v := x - 2.25 / d1
		return n1 * v * v * 0.9375
	} else {
		v := x - 2.625 / d1
		return n1 * v * v * 0.984375
	}
}

pub fn ease_inout_bounce(x f64) f64 {
	return if x < 0.5  { (1.0 - ease_out_bounce(1.0 - 2.0 * x)) / 2.0 }  else  { (1.0 + ease_out_bounce(2.0 * x - 1.0)) / 2.0 }
}


