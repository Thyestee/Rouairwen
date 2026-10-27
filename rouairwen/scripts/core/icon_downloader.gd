class_name IconDownloader
extends Node
## Downloads the WoW icons a shared build is missing into user://icons, in the background on launch.
## Builds don't ship Blizzard's icon files; until (or unless) this succeeds, the drawn icons are used.

signal finished(downloaded: int)


func start() -> void:
	var names := WowIcons.missing_names()
	if names.is_empty():
		queue_free()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WowIcons.USER_DIR))
	var http := HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	var got := 0
	for icon_name in names:
		var file := ProjectSettings.globalize_path(WowIcons.user_path(icon_name))
		http.download_file = file
		if http.request(WowIcons.URL % icon_name) != OK:
			break
		var res: Array = await http.request_completed
		if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
			got += 1
		else:
			DirAccess.remove_absolute(file)
			if res[0] != HTTPRequest.RESULT_SUCCESS:
				break  # Offline: keep the drawn icons and try again next launch.
	WowIcons.clear_cache()
	finished.emit(got)
	queue_free()
