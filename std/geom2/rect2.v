module geom2

pub struct Rect2 {
	pub mut:
	a Vec2
	b Vec2
}

pub fn Rect2.from_size(from Vec2, size Vec2) Rect2 {
	return Rect2{from, from + size}
}


@[inline]
pub fn (rect Rect2) size() Vec2 {
	return Vec2{f64_abs(rect.b.x - rect.a.x), f64_abs(rect.b.y - rect.a.y)}
}

@[inline]
pub fn (rect Rect2) area() f64 {
	return rect.size().x * rect.size().y
}

@[inline]
pub fn (rect Rect2) left()   f64 { return f64_min(rect.a.x, rect.b.x) }
@[inline]
pub fn (rect Rect2) right()  f64 { return f64_max(rect.a.x, rect.b.x) }
@[inline]
pub fn (rect Rect2) top()    f64 { return f64_min(rect.a.y, rect.b.y) }
@[inline]
pub fn (rect Rect2) bottom() f64 { return f64_max(rect.a.y, rect.b.y) }



pub fn (rect Rect2) is_point_inside(p Vec2) bool {
	return rect.a.x < p.x && p.x <= rect.b.x  &&  rect.a.y < p.y && p.y <= rect.b.y
}

pub fn Rect2.get_overlap_area(a Rect2, b Rect2) f64 {
	if a.area() == 0.0 || b.area() == 0.0 { return 0.0 }
	
	overlap_width := f64_min(a.right(), b.right()) - f64_max(a.left(), b.left())
	overlap_height := f64_min(a.bottom(), b.bottom()) - f64_max(a.top(), b.top())
	
	if overlap_height <= 0.0 || overlap_width <= 0.0 { return 0.0 }
	return overlap_width * overlap_height
}
