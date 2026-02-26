module mirrorlib

// List of basic action codes for easier use

pub const action_join_session                  := u32(1)
pub const action_create_session                := u32(2)
pub const action_user_connected                := u32(3)
pub const action_session_code_confirmation     := u32(4)
pub const action_heartbeat                     := u32(5)
pub const action_server_error                  := u32(6)
pub const action_session_join_confirmation     := u32(7)

pub const internal_actions                     := [ u32(1), 2, 3, 4, 5, 6, 7 ]
