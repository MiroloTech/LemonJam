module engine

import audio.core.miniaudio as ma

@[heap] // @[manualfree]
pub struct AudioDevice {
	pub mut:
	playback_format               ma.Format               = .s32
	playback_channels             u32                     = 1
	playback_sample_rate          u32                     = 44100
	
	wave_callback                 ?fn (frames u32, sample_rate u32, channels u32) []f64
	// user_data                     voidptr                 = unsafe { nil } // Use closures
	
	mut:
	ma_device                     &ma.Device              = unsafe { nil }
	t                             f64
	// TODO : Add stack here to read the last n pcm frames for pretty visuals (put into context and give to effetcs and instruments)
}

pub fn (mut device AudioDevice) init() ! {
	mut config  := ma.device_config_init(.playback)
	config.playback.format    = device.playback_format
	config.playback.channels  = device.playback_channels
	config.sampleRate         = device.playback_sample_rate
	config.pUserData          = device
	config.dataCallback       = fn (ma_device &ma.Device, output voidptr, _ voidptr, frame_count u32) {
		mut device := unsafe { &AudioDevice(ma_device.pUserData) }
		// sample_count := u64(device.playback_channels) * u64(device.playback_sample_rate) * u64(frame_count)
		if device.wave_callback != none {
			samples := device.wave_callback(frame_count, device.playback_sample_rate, device.playback_channels)
			// samples := []f64{len: int(frame_count), init: 0.0}
			// device.t += f64(frame_count)
			/*
			if samples.len > 3 {
				if samples[0] != 0.0 && samples[1] != 0.0 && samples[2] != 0.0 {
					for i, s in samples {
						if i == samples.len - 1 {
							print("1,")
						} else {
							print("${s:.3},")
						}
					}
				}
			}
			*/
			
			// TODO : Optimize this to maybe use generics to let the caller decide, what kind of pcm frame type is returned
			
			match device.playback_format {
				.f32 {
					buffer := []f32{ len: int(frame_count), init: f32(samples[index] )}
					unsafe { vmemcpy( output, buffer.data, buffer.len * int(sizeof(f32)) ) }
				}
				.u8 {
					buffer := []u8{ len: int(frame_count), init: u8((samples[index] + 1.0) / 2.0 * f64(max_u8)) }
					unsafe { vmemcpy( output, buffer.data, buffer.len * int(sizeof(u8)) ) }
				}
				.s16 {
					buffer := []i16{ len: int(frame_count), init: i16(samples[index] * f64(max_i16)) }
					unsafe { vmemcpy( output, buffer.data, buffer.len * i16(sizeof(i16)) ) }
				}
				.s32 {
					buffer := []i32{ len: int(frame_count), init: i32(samples[index] * f64(max_i32)) }
					unsafe { vmemcpy( output, buffer.data, buffer.len * i16(sizeof(i32)) ) }
				}
				
				// TODO : s24
				else {
					
				}
			}
		}
	}
		
	// ma_device := &ma.Device{}
	mut ma_device := unsafe { &ma.Device(vcalloc(int(sizeof(ma.Device)))) }
	result := ma.device_init(ma.null, &config, ma_device);
	if result != .success {
		return error("Failed to construct miniaudio playback device : ${result}")
	}
	ma.device_start(ma_device)
	device.ma_device = ma_device
}


pub fn (device AudioDevice) cleanup() {
	if !isnil(device.ma_device) {
		ma.device_uninit(device.ma_device)
	}
}

