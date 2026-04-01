module project

import os
import v.vmod
import compress.szip

const resource_zip := $embed_file("res.zip")

// Returns the path to the AppData folder, which contains resources, that can't be embeded properly here. This folder should be created by an installer. This panics, if the folder doesn't exist.
pub fn get_appdata_path() string {
	app_data := os.config_dir() or { panic("Failed to fetch AppData folder : ${err}") }
	vm := vmod.decode(@VMOD_FILE) or { panic("Failed to parse .vmod file to determine proper project name : ${err}") }
	path := os.join_path(app_data, vm.name)
	if os.is_dir(path) {
		return path
	} else {
		panic("${vm.name} folder doesn't exist in AppData directory '${app_data}'")
	}
}

// Creates a folder in the AppData folder, if it not already exists
fn make_appdata_folder() {
	app_data := os.config_dir() or { panic("Failed to fetch AppData folder : ${err}") }
	vm := vmod.decode(@VMOD_FILE) or { panic("Failed to parse .vmod file to determine proper project name : ${err}") }
	path := os.join_path(app_data, vm.name)
	if os.is_dir(path) {
		return
	}
	os.mkdir(path) or { panic("Failed to create ${vm.name} folder in AppData folder ${app_data} : ${err}") }
}

// Extracts the embeded resource folder into a new appdata folder (doesn't overwrite files)
pub fn extract_appdata() {
	// Save zip folder to temp
	temp_path := os.join_path(os.temp_dir(), "lmnj_res.zip")
	os.create(temp_path) or { panic("Failed to create temp res file at dir ${temp_path} : ${err}") }
	os.write_file(temp_path, resource_zip.to_string()) or { panic("Failed to write to temp res file : ${err}") }
	
	// Extract fodler
	// TODO : Check, if this extraction overwrites anything
	make_appdata_folder()
	success := szip.extract_zip_to_dir(temp_path, get_appdata_path()) or {
		panic("Failed to extract 7zip file from embeded LemonJam program to an AppData folder : ${err}")
	}
	if success != true {
		panic("Failed to extract 7zip file from embeded LemonJam program to an AppData folder")
	}
	
	// > Move inner folders one level above (make res folder empty)
	res_path := os.join_path(get_appdata_path(), "res")
	res_entries := os.ls(res_path) or { panic("Failed to itterate through res folder in AppData : ${err}") }
	for entry in res_entries {
		path := os.join_path(res_path, entry)
		target_path := os.join_path(get_appdata_path(), entry)
		sub_entries := os.ls(path) or { [] }
		
		// >> Create top-level dir
		os.mkdir(target_path) or {  }
		
		// >> Move every sub-element to top-level folder
		for sub_entry in sub_entries {
			sub_path := os.join_path(path, sub_entry)
			/*
			// This only places new resources in the folders, while leaving old and modified ones untouched
			if !os.exists(os.join_path(target_path, sub_entry)) {
				os.mv(sub_path, target_path) or { continue }
			}
			*/
			
			// This may overwrite existing modifications, which is often intended
			if os.exists(os.join_path(target_path, sub_entry)) {
				os.rm(os.join_path(target_path, sub_entry)) or {  }
			}
			os.mv(sub_path, target_path) or { continue }
		}
	}
	
	// >> Remove old res folder
	os.rmdir_all(res_path) or {
		eprintln("Failed to remove old res/ folder in AppData : ${err}")
	}
	
	// Delete old .zip from temp
	// os.rm(temp_path) or { panic("Failed to remove temp res file from path '${temp_path}' : ${err}") }
	
	println("AppData under ${get_appdata_path()}")
}
