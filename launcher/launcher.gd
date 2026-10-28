extends Control
## Lumens launcher: checks the latest GitHub release, downloads and installs it when it differs from
## the installed copy, then starts the game. Every release must carry Lumens-windows.zip with
## Lumens.exe inside, as the game's releases always have.
##
## The game is installed in the launcher's data folder (%APPDATA%\Lumens Launcher\game), so the
## launcher works from anywhere. The game's saves live in its own folder and are never touched.
##
## Test options (after "--"): --install-dir=<folder> installs there instead; --repo=<owner/name> reads
## another repository's releases; --screenshot=<png> saves the window when done; --check-only updates
## and quits without starting the game, printing what happened.

const REPO := "Thyestee/Rouairwen"
const API := "https://api.github.com/repos/%s/releases/latest"
const ASSET := "Lumens-windows.zip"
const EXE := "Lumens.exe"
const HEADERS := ["User-Agent: Lumens-Launcher", "Accept: application/vnd.github+json"]

const TEXT := Color("f4e8d8")
const MUTED := Color("c09f86")
const GOLD := Color("ffd86b")
const GOOD := Color("6ee06e")
const BAD := Color("ff6a5a")
const HEADING_FONTS := ["Georgia", "Palatino Linotype", "Book Antiqua", "Times New Roman", "serif"]
const BODY_FONTS := ["Segoe UI", "Trebuchet MS", "Verdana", "sans-serif"]

var install_dir := ""
var check_only := false
var repo := REPO
var screenshot := ""
var http: HTTPRequest
## {tag, name, url, size, notes} of the latest release
var latest := {}
var installed := ""
var downloading := false

var status: Label
var detail: Label
var bar: ProgressBar
var notes: RichTextLabel
var play: Button
var retry: Button


func _ready() -> void:
	install_dir = OS.get_user_data_dir().path_join("game")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--install-dir="):
			install_dir = arg.trim_prefix("--install-dir=")
		elif arg.begins_with("--repo="):
			repo = arg.trim_prefix("--repo=")
		elif arg.begins_with("--screenshot="):
			screenshot = arg.trim_prefix("--screenshot=")
		elif arg == "--check-only":
			check_only = true
	DirAccess.make_dir_recursive_absolute(install_dir)
	installed = _read_installed()
	http = HTTPRequest.new()
	http.timeout = 30.0
	http.use_threads = true
	add_child(http)
	_build_ui()
	_check()


func _exe_path() -> String:
	return install_dir.path_join(EXE)


func _read_installed() -> String:
	var f := FileAccess.open(install_dir.path_join("version.txt"), FileAccess.READ)
	if f == null or not FileAccess.file_exists(_exe_path()):
		return ""
	return f.get_as_text().strip_edges()


# ---------------------------------------------------------------- update flow

func _check() -> void:
	_set_state("Checking for updates…", "", false)
	retry.visible = false
	bar.visible = false
	var err := http.request(API % repo, HEADERS)
	if err != OK:
		_offline("Couldn't reach GitHub (error %d)." % err)
		return
	var res: Array = await http.request_completed
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		var why := "no connection" if res[0] != HTTPRequest.RESULT_SUCCESS else "HTTP %d" % res[1]
		_offline("Couldn't check for updates (%s)." % why)
		return
	var data = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if not data is Dictionary:
		_offline("GitHub sent an unreadable answer.")
		return
	latest = {"tag": data.get("tag_name", ""), "name": data.get("name", ""), "notes": data.get("body", "")}
	for a in data.get("assets", []):
		if a.get("name", "") == ASSET:
			latest["url"] = a["browser_download_url"]
			latest["size"] = int(a.get("size", 0))
	notes.text = _markdown(latest["name"], latest["notes"])
	if not latest.has("url"):
		_offline("The latest release (%s) has no %s to download." % [latest["tag"], ASSET])
	elif latest["tag"] == installed:
		_ready_to_play("Lumens %s is up to date." % installed)
	else:
		_download()


func _download() -> void:
	var part := install_dir.path_join(ASSET + ".part")
	DirAccess.remove_absolute(part)
	http.download_file = part
	downloading = true
	bar.visible = true
	bar.value = 0.0
	_set_state("Downloading Lumens %s…" % latest["tag"], "", false)
	var err := http.request(latest["url"], HEADERS)
	if err != OK:
		downloading = false
		_offline("The download couldn't start (error %d)." % err)
		return
	var res: Array = await http.request_completed
	downloading = false
	http.download_file = ""
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		DirAccess.remove_absolute(part)
		_offline("The download failed (%s)." % ("no connection" if res[0] != HTTPRequest.RESULT_SUCCESS else "HTTP %d" % res[1]))
		return
	_set_state("Installing Lumens %s…" % latest["tag"], "", false)
	bar.value = 100.0
	# Let the window show the message before the heavy unzip.
	await get_tree().process_frame
	await get_tree().process_frame
	var problem := _install(part)
	DirAccess.remove_absolute(part)
	if problem != "":
		_offline(problem)
		return
	installed = latest["tag"]
	_ready_to_play("Lumens %s is installed." % installed)


## Unzips the game next to the old one, then swaps them. Returns what went wrong, or "".
func _install(zip_path: String) -> String:
	var zip := ZIPReader.new()
	if zip.open(zip_path) != OK:
		return "The download is damaged. Retry to download it again."
	var inside := ""
	for f in zip.get_files():
		if f.get_file() == EXE:
			inside = f
	if inside == "":
		zip.close()
		return "The download has no %s inside." % EXE
	var bytes := zip.read_file(inside)
	zip.close()
	var fresh := _exe_path() + ".new"
	var out := FileAccess.open(fresh, FileAccess.WRITE)
	if out == null:
		return "Couldn't write to %s." % install_dir
	out.store_buffer(bytes)
	out.close()
	if FileAccess.file_exists(_exe_path()) and DirAccess.remove_absolute(_exe_path()) != OK:
		DirAccess.remove_absolute(fresh)
		return "Lumens is still running: close it, then retry."
	if DirAccess.rename_absolute(fresh, _exe_path()) != OK:
		return "Couldn't put the new version in place."
	var v := FileAccess.open(install_dir.path_join("version.txt"), FileAccess.WRITE)
	v.store_string(latest["tag"])
	v.close()
	return ""


## Something went wrong: play the installed copy if there is one, otherwise offer a retry.
func _offline(problem: String) -> void:
	bar.visible = false
	retry.visible = true
	if installed != "":
		_ready_to_play("Lumens %s (installed)" % installed, problem + " You can still play the installed version.")
	else:
		_set_state("Lumens isn't installed yet.", problem, false)
		if check_only:
			_finish()


func _ready_to_play(message: String, note := "") -> void:
	bar.visible = false
	var line := note
	if note == "" and latest.has("tag") and latest["tag"] == installed:
		line = "Ready to play."
	_set_state(message, line, true)
	if check_only:
		_finish()


func _finish() -> void:
	if screenshot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(screenshot)
	print("Launcher: %s %s (installed: %s, latest: %s)" % [status.text, detail.text, installed if installed != "" else "none",
		latest.get("tag", "unknown")])
	get_tree().quit()


func _play() -> void:
	if play.disabled:
		return
	var pid := OS.create_process(_exe_path(), [])
	if pid < 0:
		_set_state("Lumens couldn't start.", "Retry, or check %s." % install_dir, true)
		return
	get_tree().quit()


func _process(_d: float) -> void:
	if downloading:
		var total := http.get_body_size()
		if total <= 0:
			total = latest.get("size", 0)
		var got := http.get_downloaded_bytes()
		if total > 0:
			bar.value = 100.0 * got / total
			detail.text = "%.1f / %.1f MB" % [got / 1048576.0, total / 1048576.0]


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_accept"):
		_play()


func _set_state(message: String, line: String, can_play: bool) -> void:
	status.text = message
	detail.text = line
	play.disabled = not can_play
	detail.add_theme_color_override("font_color", BAD if line.contains("Couldn't") or line.contains("failed") \
		or line.contains("damaged") or line.contains("running") else MUTED)
	status.add_theme_color_override("font_color", GOOD if can_play and line == "Ready to play." else TEXT)


# ---------------------------------------------------------------- release notes

## Release notes from GitHub (Markdown) as BBCode: headings, bold, bullets, links shown as text.
func _markdown(title: String, md: String) -> String:
	var out := ["[font_size=19][color=#ffd86b]%s[/color][/font_size]" % title]
	for raw in md.replace("\r", "").split("\n"):
		var line := String(raw)
		if line.begins_with("## How to play"):
			break
		var bold := RegEx.create_from_string("\\*\\*(.+?)\\*\\*")
		line = bold.sub(line, "[b]$1[/b]", true)
		line = RegEx.create_from_string("\\[([^\\]]+)\\]\\([^)]+\\)").sub(line, "$1", true)
		line = RegEx.create_from_string("(^|\\s)\\*([^*]+)\\*").sub(line, "$1[i]$2[/i]", true)
		if line.begins_with("## "):
			out.append("[color=#ffd86b][b]%s[/b][/color]" % line.substr(3))
		elif line.begins_with("- "):
			out.append("  •  " + line.substr(2))
		else:
			out.append(line)
	return "\n".join(out).strip_edges()


# ---------------------------------------------------------------- window

const MARGIN := 22
const LEFT_W := 260


func _build_ui() -> void:
	# Orgrimmar's gate fills the window, its doors behind the left column
	var gate: Control = preload("res://gate.gd").new()
	gate.gate_x = MARGIN + LEFT_W / 2.0
	gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(gate)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	margin.add_child(root)

	# Left: the guild's banner in front of the gate, then status and buttons
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = LEFT_W
	left.add_theme_constant_override("separation", 8)
	root.add_child(left)
	var banner_script := preload("res://banner.gd")
	var banner: Control = banner_script.new()
	banner.custom_minimum_size = Vector2(176, banner_script.height_for(176))
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(banner)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	# Status and buttons on a dark plate, readable over the doors
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", _box(Color(0.05, 0.02, 0.015, 0.82), Color("8e2a1a"), 1, 6, 10))
	left.add_child(plate)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	plate.add_child(box)
	status = _label("", 16, TEXT)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status)
	bar = ProgressBar.new()
	bar.custom_minimum_size.y = 16
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _box(Color(0.05, 0.02, 0.015), Color("6a2414"), 1, 4))
	bar.add_theme_stylebox_override("fill", _box(Color("a3241a"), Color.TRANSPARENT, 0, 4))
	box.add_child(bar)
	detail = _label("", 13, MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(detail)
	play = _button("Play", true)
	play.custom_minimum_size.y = 50
	play.add_theme_font_size_override("font_size", 24)
	play.pressed.connect(_play)
	box.add_child(play)
	retry = _button("Check again", false)
	retry.pressed.connect(_check)
	box.add_child(retry)

	# Right: what's new in the latest release, the wall showing through
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color(0.06, 0.025, 0.02, 0.82), Color("8e2a1a"), 2, 6, 14))
	root.add_child(panel)
	notes = RichTextLabel.new()
	notes.bbcode_enabled = true
	notes.scroll_active = true
	notes.add_theme_font_override("normal_font", _font(BODY_FONTS, 500))
	notes.add_theme_font_override("bold_font", _font(BODY_FONTS, 700))
	notes.add_theme_font_size_override("normal_font_size", 13)
	notes.add_theme_font_size_override("bold_font_size", 13)
	notes.add_theme_color_override("default_color", TEXT)
	notes.text = "[color=#8a7262]What's new appears here.[/color]"
	panel.add_child(notes)


func _label(text: String, size: int, color: Color, heading := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font(HEADING_FONTS if heading else BODY_FONTS, 700 if heading else 500))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", _font(BODY_FONTS, 700))
	b.add_theme_font_size_override("font_size", 16)
	var base := Color("a3241a") if primary else Color("3d1a10")
	b.add_theme_stylebox_override("normal", _box(base, Color("b8892f") if primary else Color("8e2a1a"), 2, 6))
	b.add_theme_stylebox_override("hover", _box(base.lightened(0.15), GOLD, 2, 6))
	b.add_theme_stylebox_override("pressed", _box(base.darkened(0.25), GOLD, 2, 6))
	b.add_theme_stylebox_override("disabled", _box(Color(0.15, 0.08, 0.06), Color(0.3, 0.2, 0.15), 2, 6))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.42, 0.36))
	return b


func _box(bg: Color, border: Color, width: int, radius: int, pad := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s


func _font(names: Array, weight: int) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	f.font_weight = weight
	return f
