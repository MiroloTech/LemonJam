module geom2

import math { sqrt, sign, abs }

// Calculates the intersection between the infinite line, defined by the ```line_a``` and ```line_b``` points, and a circle, defined by its center ```center``` and radius ```radius```
// Returns 0 points on no intersection, 1 point on single, perfect edge intersection and 2 points on full intersection (sorted by proximity to ```line_a```)
// Reference : https://mathworld.wolfram.com/Circle-LineIntersection.html [31.01.2026]
pub fn intersection_circle_line(line_a Vec2, line_b Vec2, center Vec2, radius f64) []Vec2 {
	x1 := line_a.x - center.x
	y1 := line_a.y - center.y
	x2 := line_b.x - center.x
	y2 := line_b.y - center.y
	
	d := Vec2{x2 - x1, y2 - y1}
	dr := sqrt(d.x * d.x + d.y * d.y)
	dd := x1 * y2 - x2 * y1
	
	discrimenant := (radius*radius) * (dr*dr) - (dd*dd)
	if discrimenant < 0 {
		return []Vec2{}
	} else if discrimenant == 0 {
		point := Vec2{
			x: (dd * d.y + sign(d.y) * d.x * sqrt(discrimenant)) / (dr * dr)
			y: (-dd * d.x + abs(d.y) * sqrt(discrimenant)) / (dr * dr)
		} + center
		return [point]
	} else {
		point1 := Vec2{
			x: (dd * d.y + sign(d.y) * d.x * sqrt(discrimenant)) / (dr * dr)
			y: (-dd * d.x + abs(d.y) * sqrt(discrimenant)) / (dr * dr)
		} + center
		point2 := Vec2{
			x: (dd * d.y - sign(d.y) * d.x * sqrt(discrimenant)) / (dr * dr)
			y: (-dd * d.x - abs(d.y) * sqrt(discrimenant)) / (dr * dr)
		} + center
		if point1.distance_to(line_a) < point2.distance_to(line_a) {
			return [point1, point2]
		} else {
			return [point2, point1]
		}
	}
}
