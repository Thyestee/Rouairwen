extends SceneTree
## Looks up the WoW icon of every guildmate talent and ability on Wowhead (Classic first, then TBC and
## WotLK for later talents) and writes scripts/data/talent_icons.gd. Then run tools/fetch_icons.gd to
## download the icons. Run: godot --headless --path . --script res://tools/resolve_talent_icons.gd

const OUT := "res://scripts/data/talent_icons.gd"
const SEARCH := "https://www.wowhead.com/%s/search/suggestions-template?q=%s"
const VERSIONS := ["classic", "tbc", "wotlk"]

var http: HTTPRequest
var _cache := {}


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	http = HTTPRequest.new()
	http.timeout = 20.0
	root.add_child(http)
	# Icons found by an earlier run are kept.
	var known := {}
	if FileAccess.file_exists(OUT):
		known = (load(OUT) as Script).get_script_constant_map().get("TALENTS", {})
	var talents := {}
	var missing := []
	for spec_id in SpecTalents.TREES:
		var cls := ClassData.class_of(spec_id)
		for t in SpecTalents.tree(spec_id):
			var key := "%s/%s" % [cls, t[0]]
			if talents.has(key) or key in missing:
				continue
			if known.has(key):
				talents[key] = known[key]
				continue
			var icon := await _find(t[1], ClassData.class_name_of(cls))
			# "Improved Rend" and the like use their spell's icon.
			if icon == "" and String(t[1]).begins_with("Improved "):
				icon = await _find(String(t[1]).trim_prefix("Improved "), ClassData.class_name_of(cls))
			if icon == "":
				missing.append(key)
			else:
				talents[key] = icon
	var abilities := {}
	for id in SpecTalents.ABILITIES:
		for key in talents:
			if String(key).ends_with("/" + id):
				abilities[id] = talents[key]
				break
	var lines := ["class_name TalentIcons",
		"## Icons of guildmate talents and abilities, looked up on Wowhead by tools/resolve_talent_icons.gd.",
		"## Generated: change the talent trees, then run the tool again rather than editing this file.", "",
		"## Ability id -> icon name.", "const ABILITIES := {"]
	for id in abilities:
		lines.append("\t\"%s\": \"%s\"," % [id, abilities[id]])
	lines += ["}", "", "## \"<class>/<talent id>\" -> icon name.", "const TALENTS := {"]
	for key in talents:
		lines.append("\t\"%s\": \"%s\"," % [key, talents[key]])
	lines.append("}")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("%d talent icons, %d of %d abilities" % [talents.size(), abilities.size(), SpecTalents.ABILITIES.size()])
	for m in missing:
		print("  not found: " + m)
	quit()


## The icon of the spell with exactly this name, preferring one of the class's talents.
func _find(spell_name: String, class_label: String) -> String:
	for version in VERSIONS:
		var results := await _search(version, spell_name)
		var best := {}
		var best_score := -1
		for r in results:
			if r.get("typeName", "") != "Spell" or r.get("name", "") != spell_name or r.get("icon", "") == "":
				continue
			var crumbs: Array = r.get("pinBreadcrumb", [])
			var score := (2 if class_label in crumbs else 0) + (1 if "Talents" in crumbs else 0)
			if score > best_score:
				best = r
				best_score = score
		if not best.is_empty():
			return best["icon"]
	return ""


func _search(version: String, spell_name: String) -> Array:
	var key := version + "|" + spell_name
	if _cache.has(key):
		return _cache[key]
	# Wowhead refuses requests that come too fast: wait longer after each refusal.
	for attempt in 5:
		await create_timer(0.4 + 4.0 * attempt).timeout
		if http.request(SEARCH % [version, spell_name.uri_encode()], ["User-Agent: Mozilla/5.0"]) != OK:
			continue
		var res: Array = await http.request_completed
		if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
			var data = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
			var out: Array = data.get("results", []) if data is Dictionary else []
			_cache[key] = out
			return out
		print("  %s: HTTP %d, retrying" % [spell_name, res[1]])
	return []
