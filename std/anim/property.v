module anim

import std.ease { EaseFn, linear }

pub struct AnimProperty[T] {
	pub mut:
	easing   EaseFn = linear
	from     T
	to       T
}

pub fn (prop AnimProperty[T]) get(x f64) T {
	if x <= 0.0 { return prop.from }
	if x >= 1.0 { return prop.to }
	
	ex := prop.easing(x)
	
	$if       T is f64                      { return prop.from + T(ex) * (prop.to - prop.from) }
	$else $if T is f32                      { return prop.from + T(ex) * (prop.to - prop.from) }
	$else $if T is i64                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is int                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is i16                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is i8                       { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is u64                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is u32                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is u16                      { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else $if T is u8                       { return T( (f64(prop.from) + ex * f64(prop.to - prop.from)) ) }
	$else                                   { return if ex > 0.5 { prop.to } else { prop.from } }
}
