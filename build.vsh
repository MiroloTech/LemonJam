#!/usr/bin/env -S v run

import compress.szip
import v.vmod

// Allow embedding of extyrenal resources as .zip
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

println("Build process completed")
