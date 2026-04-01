module mirrorlib

// List of basic action codes for easier use
// TODO : Make this an enum

pub const action_join_session                  := u32(1)
pub const action_create_session                := u32(2)
pub const action_user_connected                := u32(3)
pub const action_session_code_confirmation     := u32(4)
pub const action_heartbeat                     := u32(5)
pub const action_server_error                  := u32(6)
pub const action_session_join_confirmation     := u32(7)
pub const action_new_nid                       := u32(8)
pub const action_element_create                := u32(9)
pub const action_element_update                := u32(10)
pub const action_element_delete                := u32(11)
pub const action_element_lock                  := u32(12)
pub const action_element_unlock                := u32(13)

pub const internal_actions                     := [ u32(1), 2, 3, 4, 5, 6, 7 ]

pub const action_tags := {
	action_join_session:                          "action_join_session",
	action_create_session:                        "action_create_session",
	action_user_connected:                        "action_user_connected",
	action_session_code_confirmation:             "action_session_code_confirmation",
	action_heartbeat:                             "action_heartbeat",
	action_server_error:                          "action_server_error",
	action_session_join_confirmation:             "action_session_join_confirmation",
	action_new_nid:                               "action_new_nid",
	action_element_create:                        "action_element_create",
	action_element_update:                        "action_element_update",
	action_element_delete:                        "action_element_delete",
	action_element_lock:                          "action_element_lock",
	action_element_unlock:                        "action_element_unlock",
}
