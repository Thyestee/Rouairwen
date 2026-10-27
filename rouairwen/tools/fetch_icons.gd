extends SceneTree
## Downloads the WoW icons listed in WowIcons from Wowhead's icon CDN into assets/icons/ (git-ignored).
## Icons already on disk are skipped. Run: godot --headless --path . --script res://tools/fetch_icons.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var dir := ProjectSettings.globalize_path(WowIcons.DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var http := HTTPRequest.new()
	http.timeout = 20.0
	root.add_child(http)
	var got := 0
	var skipped := 0
	var missing := []
	for icon_name in WowIcons.all_names():
		var file := dir.path_join(icon_name + ".jpg")
		if FileAccess.file_exists(file):
			skipped += 1
			continue
		http.download_file = file
		var err := http.request(WowIcons.URL % icon_name)
		if err != OK:
			missing.append("%s (request error %d)" % [icon_name, err])
			continue
		var res: Array = await http.request_completed
		if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
			got += 1
		else:
			DirAccess.remove_absolute(file)
			missing.append("%s (HTTP %d)" % [icon_name, res[1]])
	print("Icons: %d downloaded, %d already present, %d missing" % [got, skipped, missing.size()])
	for m in missing:
		print("  missing: " + m)
	quit(0 if missing.is_empty() else 1)
