module geom2

pub struct Tri2 {
	pub mut:
	a   Vec2
	b   Vec2
	c   Vec2
}

pub fn (tri Tri2) offset(o Vec2) Tri2 {
	return Tri2{
		tri.a + o
		tri.b + o
		tri.c + o
	}
}

pub fn (tri Tri2) scale(s Vec2) Tri2 {
	return Tri2{
		tri.a * s
		tri.b * s
		tri.c * s
	}
}

pub fn (tri Tri2) is_ccw() bool {
	return (tri.b.x - tri.a.x) * (tri.c.y - tri.a.y) - (tri.b.y - tri.a.y) * (tri.c.x - tri.a.x) >= 0.0
}

pub fn (tri Tri2) is_cw() bool {
	return (tri.b.x - tri.a.x) * (tri.c.y - tri.a.y) - (tri.b.y - tri.a.y) * (tri.c.x - tri.a.x) <= 0.0
}

pub fn (tri Tri2) is_collinear() bool {
	return (tri.b.x - tri.a.x) * (tri.c.y - tri.a.y) - (tri.b.y - tri.a.y) * (tri.c.x - tri.a.x) == 0.0
}

// ========== UTIL ==========

// Uses ear-clipping to triangulate the given concave shape profile
pub fn Tri2.triangulate(shape []Vec2) []Tri2 {
	if shape.len < 3 {
		return []Tri2{}
	}
	
	mut pts := shape.clone()
	mut tris := []Tri2{}
	mut i := 0
	for _ in 0..5000 {
		// > Wrap i properly to always go in a circle
		i = i % pts.len
		
		// > Get next three points
		p0 := pts[i]
		p1 := pts[(i + 1) % pts.len]
		p2 := pts[(i + 2) % pts.len]
		tri := Tri2{p0, p1, p2}
		
		// > Check winding order of triangle (assuming ccw is inside)
		if tri.is_ccw() { //  || tri.is_collinear()
			pts.delete((i + 1) % pts.len)
			tris << tri
			i += 2
		} else {
			i += 1
		}
		
		if pts.len < 3 { break }
	}
	
	if pts.len > 4 {
		// log.error("Triangulation finished unsucessfully : ${pts.len} points remain")
	} else if pts.len == 3 {
		tris << Tri2{pts[0], pts[1], pts[2]}
	}
	
	return tris
}
