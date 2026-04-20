module app

pub fn (mut project Project) cleanup() {
	// Cleanup old dl insturment handels for loading instruments
	for mut instrument in project.instruments {
		instrument.cleanup()
	}
}
