module objs

// TODO : this

@[heap]
pub struct Sound {
    pub mut:
    name          string
    path          string
    sample_rate   u32
    channels      u32
}
