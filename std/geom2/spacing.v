module geom2

pub struct Spacing {
	pub mut:
	top      f64
	bottom   f64
	left     f64
	right    f64
}

pub fn Spacing.value(v f64) Spacing {
	return Spacing{v, v, v, v}
}
