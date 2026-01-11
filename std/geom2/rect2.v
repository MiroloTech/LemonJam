module geom2

pub struct Rect2 {
	pub mut:
	a Vec2
	b Vec2
}

pub fn (rect Rect2) is_point_inside(p Vec2) bool {
	return rect.a.x < p.x && p.x <= rect.b.x  &&  rect.a.y < p.y && p.y <= rect.b.y
}

pub fn Rect2.from_size(from Vec2, size Vec2) Rect2 {
	return Rect2{from, from + size}
}

pub fn (rect Rect2) size() Vec2 {
	return rect.b - rect.a
}
