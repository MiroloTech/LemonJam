module mirrorlib

import os

pub interface NetworkInstance {
	is_server      bool
	
	mut:
	user_data      voidptr
	on_packet      ?FnOnPacket
    
    send_packet(packet Packet)
    close() !
}


pub fn get_open_ip6() ?string {
    $if linux {
        out := os.execute('ip -6 addr show scope global').output
        for line in out.split_into_lines() {
            if line.contains('inet6') {
                return line.all_after('inet6 ').all_before('/')
            }
        }
    }

    $if windows {
        out := os.execute('powershell -Command "Get-NetIPAddress -AddressFamily IPv6 | Where-Object {\$_.PrefixOrigin -ne \\"WellKnown\\"} | Select -ExpandProperty IPAddress"').output
        for line in out.split_into_lines() {
            if line.contains(':') {
                return line.trim_space()
            }
        }
    }

    return none
}

