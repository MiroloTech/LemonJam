module audio

import math { pow, log2 }

pub fn note2freq(note f64) f64 {
    return 440.0 * pow(2, (note - 69.0) / 12.0)
}

pub fn freq2note(freq f64) f64 {
	return log2(freq / 440.0) * 12.0 + 69.0
}

pub fn tag2note(tag string) f64 {
	tags           := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	tags_secondary := ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "H"]
	
	mut note_text := "" + tag
	mut halftone_tag := "" + tag
	for n in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"] {
		halftone_tag = halftone_tag.replace(n, "")
	}
	
	mut halftone := -1
	for i, t in tags {
		if halftone_tag == t {
			halftone = i
			note_text = note_text.replace(t, "")
		}
	}
	if halftone == -1 {
		for i, t in tags_secondary {
			if halftone_tag == t {
				halftone = i
				note_text = note_text.replace(t, "") 
			}
		}
	}
	
	if halftone == -1 {
		return 60
	}
	
	mut octave := note_text.int()
	
	return f64(octave) * 12.0 + f64(halftone)
}
