#!/usr/bin/env -S v run

import compress.szip
import v.vmod

// Allow embedding of extyrenal resources as .zip
println("Packaging basic app resources...")

// > Zip the res/ folder
szip.zip_folder("res/", "res.zip") or {
	panic("Failed to build project : Failed to zip resource folder : ${err}")
}

// > Compile project
system("v .")

// > Remove zipped res.zip file
// rm("res.zip") or {  }

// Compress .exe file for easier transfer
// > Create a target folder
mkdir("target/") or {  }

vm := vmod.decode(@VMOD_FILE)!
version_tag := "v" + vm.version.replace(".", "-")

// > Delete old .zip file
target_zip_file := "target/LemonJam_${version_tag}.zip"
rm(target_zip_file) or {  }

// > Zip that folder
szip.zip_files(["LemonJam.exe"], target_zip_file) or {
	eprintln("Failed to zip project file to target folder : ${err}")
}

// Compile every instrument in the elements/instruments folder as a shared library and move them to the instruments folder in AppData as a test
target_instrument_folder := join_path(config_dir() or { panic("Failed to get config dir (AppData) folder") }, "LemonJam", "instruments")

// > Get every file in instruments folder
instruments := ls("elements/instruments") or { [] }
for entry in instruments {
	if !is_dir("elements/instruments/${entry}") {
		continue
	}
	
	println("Compiling instrument '${entry}'...")
	
	// > Compile instrument
	result := execute("v -shared elements/instruments/${entry}") // -prod 
	if result.output != "" {
		println(result.output)
	}
	// TODO : Support compiling for linux and mac too.
	
	// > Get paths to main .json file and dl file
	json_path := "elements/instruments/${entry}/${entry}.json"
	dll_path := "elements/instruments/${entry}/${entry}.dll"
	
	if !is_file(json_path) {
		eprintln("Instrument '${entry}' missing a matching .json file. Make sure, that the '${entry}' folder contains a '${entry}.json file with the neccesssarry data.")
		continue
	}
	
	// > Move
	cp(json_path, target_instrument_folder) or {
		eprintln("Failed to move .json file to target folder '${target_instrument_folder}' : ${err}")
		continue
	}
	cp(dll_path, target_instrument_folder) or {
		eprintln("Failed to move .dll file to target folder '${target_instrument_folder}' : ${err}")
		continue
	}
}

println("Build process completed")
