module objs

import std { Color }
import mirrorlib { NID }

@[heap]
pub struct Sound implements TrackObject {
    pub mut:
    nid           &NID
    name          string
    path          string
    sample_rate   u32
    channels      u32
	color         Color
}
