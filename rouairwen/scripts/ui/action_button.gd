class_name ActionButton
extends TipButton
## A spell on the action bar: icon, keybind, cooldown sweep, and a tint when out of mana.

var spell_id := ""
## The key binding it shows (Settings.keys), and that binding's short label.
var action := ""
var key := ""
var engine: CombatEngine
var spell_icon: SpellIcon
var overlay: Control
var is_potion := false


func setup(p_id: String, p_action: String, p_engine: CombatEngine, level: int) -> ActionButton:
	spell_id = p_id
	action = p_action
	key = Settings.key_short(action)
	engine = p_engine
	custom_minimum_size = Vector2(54, 54)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(st, empty)
	if is_potion:
		var r := Game.best_stock_rank("mana_potion")
		spell_icon = SpellIcon.new("mana_potion", WowIcons.consumable(ShopData.rank_name("mana_potion", maxi(r, 0))))
	else:
		spell_icon = SpellIcon.new(Spells.BOOK[p_id]["icon"], WowIcons.spell(p_id, level))
	spell_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(spell_icon)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	var key_line := "\n[color=#8a7262]Key: %s[/color]" % Settings.key_label(action) if key != "" else ""
	if is_potion:
		set_tip("[b]Mana Potion[/b]\nDrink your best mana potion. 60s cooldown.%s" % key_line)
	else:
		var s: Dictionary = Spells.BOOK[p_id]
		var cast_txt := "Instant" if s["cast"] == 0.0 else ("Channeled (%.1f sec)" % s["cast"] if s.get("channel", 0) else "%.1f sec cast" % s["cast"])
		var cd := "\n%d sec cooldown" % int(engine.spell_cooldown(p_id)) if s.has("cooldown") else ""
		var amount := engine.amount_text(p_id)
		var rune := Runes.spell_line(p_id, engine.runes)
		set_tip("[b]%s[/b]\n%d Mana\n%s%s\n[color=#ffd100]%s[/color]%s%s%s" % [Spells.display_name(p_id, level),
			int(engine.spell_cost(p_id)), cast_txt, cd, s["desc"], "\n" + amount if amount != "" else "", "\n" + rune if rune != "" else "", key_line])
	return self


func _process(_d: float) -> void:
	# Bindings can change from the pause menu's options.
	key = Settings.key_short(action)
	overlay.queue_redraw()


func _draw_overlay() -> void:
	var s := overlay.size
	var font := Style.bold_font()
	var cd := 0.0
	var total := 1.0
	var usable := true
	if is_potion:
		cd = engine.potion_cd
		total = 60.0
		usable = engine.mana_potions > 0
	else:
		var sp: Dictionary = Spells.BOOK[spell_id]
		cd = engine.cooldown_left(spell_id)
		total = engine.spell_cooldown(spell_id) if sp.has("cooldown") else 1.0
		if not sp.get("off_gcd", false) and engine.gcd > cd:
			cd = engine.gcd
			total = CombatEngine.GCD
		if engine.mana < engine.spell_cost(spell_id):
			overlay.draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.2, 0.8, 0.45))
	if not usable:
		overlay.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.6))
	if cd > 0.0:
		var frac := clampf(cd / total, 0.0, 1.0)
		overlay.draw_rect(Rect2(0, s.y * (1.0 - frac), s.x, s.y * frac), Color(0, 0, 0, 0.62))
		if cd > 1.6:
			var t := str(int(ceil(cd)))
			overlay.draw_string_outline(font, Vector2(0, s.y / 2 + 7), t, HORIZONTAL_ALIGNMENT_CENTER, s.x, 18, 4, Color.BLACK)
			overlay.draw_string(font, Vector2(0, s.y / 2 + 7), t, HORIZONTAL_ALIGNMENT_CENTER, s.x, 18, Color("ffd86b"))
	# Active-cast highlight
	if not is_potion and not engine.casting.is_empty() and engine.casting["id"] == spell_id:
		overlay.draw_rect(Rect2(Vector2.ZERO, s), Color("ffd86b"), false, 3.0)
	# The Lightwell's charges left while it stands
	if spell_id == "lightwell" and not engine.lightwell.is_empty():
		var glow := 0.55 + 0.3 * sin(Time.get_ticks_msec() / 150.0)
		overlay.draw_rect(Rect2(Vector2.ZERO, s), Color(1, 0.95, 0.6, glow), false, 2.5)
		var lw := str(engine.lightwell["charges"])
		overlay.draw_string_outline(font, Vector2(0, s.y - 4), lw, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 4, 14, 3, Color.BLACK)
		overlay.draw_string(font, Vector2(0, s.y - 4), lw, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 4, 14, Color("fffbe0"))
	if is_potion:
		var n := str(engine.mana_potions)
		overlay.draw_string_outline(font, Vector2(0, s.y - 4), n, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 4, 13, 3, Color.BLACK)
		overlay.draw_string(font, Vector2(0, s.y - 4), n, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 4, 13, Color.WHITE)
	overlay.draw_string_outline(font, Vector2(4, 14), key, HORIZONTAL_ALIGNMENT_LEFT, s.x, 12, 3, Color.BLACK)
	overlay.draw_string(font, Vector2(4, 14), key, HORIZONTAL_ALIGNMENT_LEFT, s.x, 12, Color("e0e0e0"))
	if is_hovered():
		overlay.draw_rect(Rect2(Vector2.ZERO, s), Color(1, 1, 1, 0.8), false, 2.0)
