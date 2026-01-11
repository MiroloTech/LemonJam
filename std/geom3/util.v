module geom3

import math

pub fn deg2rad(deg f64) f64 {
	return deg * (math.pi / 180.0)
}

pub fn rad2deg(rad f64) f64 {
	return rad * (180.0 / math.pi)
}
