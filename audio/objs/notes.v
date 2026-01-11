module objs


/*
pub fn (notes []Note) strum(offset f64, inverted bool) []Note {
	mut new_notes := []Note{}
	mut strummed := map[f64]int{}
	if inverted {
		for note in notes.sorted_with_compare(fn (a &Note, b &Note) int {
			if a.from < b.from { return -1 }
			if a.from > b.from { return 1 }
			if a.get_note(0.0) > b.get_note(0.0) { return -1 }
			if a.get_note(0.0) < b.get_note(0.0) { return 1 }
			return 0
		}) {
			new_strum := strummed[note.from] or { 0 } + 1
			strummed[note.from] = new_strum
			new_notes << Note{
				...note
				from: note.from + offset * f64(new_strum)
			}
		}
	} else {
		for note in notes.sorted_with_compare(fn (a &Note, b &Note) int {
			if a.from < b.from { return -1 }
			if a.from > b.from { return 1 }
			if a.get_note(0.0) < b.get_note(0.0) { return -1 }
			if a.get_note(0.0) > b.get_note(0.0) { return 1 }
			return 0
		}) {
			new_strum := strummed[note.from] or { 0 } + 1
			strummed[note.from] = new_strum
			new_notes << Note{
				...note
				from: note.from + offset * f64(new_strum)
			}
		}
	}
	return new_notes
}
*/
