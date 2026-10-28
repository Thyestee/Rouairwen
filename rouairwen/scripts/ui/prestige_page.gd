class_name PrestigePage
extends VBoxContainer
## The Hall of Legends: the Horde's raiding guilds ranked by prestige, and how to earn it.

const MEDALS := [Color("ffd700"), Color("d8d8e8"), Color("d9875a")]

var hub


func rebuild() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	Style.clear(self)
	add_child(Style.title("Prestige", 26))
	var sub := Style.label("The Horde's raiding guilds, ranked by all the prestige they have ever earned. Kill raid bosses to climb, " +
		"and spend prestige to train guildmates past grade A: spending never costs you rank.", 14, Style.C["muted"])
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(sub)
	var h := Style.hbox(12)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(h)
	h.add_child(_summary())
	h.add_child(_ladder())


func _summary() -> Control:
	var p := _card()
	p.custom_minimum_size.x = 400
	var v := Style.vbox(8)
	p.add_child(v)
	var total := Game.prestige_total()
	var r := Prestige.rank(total)
	var pc := Style.C["prestige"].to_html(false)
	v.add_child(Style.label("<Lumens>", 24, Style.C["gold"], true))
	v.add_child(Style.rich("[font_size=30][color=#%s]Rank #%d[/color][/font_size] [color=#c09f86]of %d guilds[/color]" % [
		"ffd700" if r == 1 else pc, r, Prestige.guild_count()], 16))
	v.add_child(Style.rich("[color=#c09f86]Prestige earned:[/color] [color=#%s]%d[/color]\n[color=#c09f86]To spend on training:[/color] [color=#%s]%d[/color]" % [
		pc, total, pc, Game.prestige()], 15))
	var ladder := Prestige.ladder(total)
	var me := 0
	for i in ladder.size():
		if ladder[i]["you"]:
			me = i
	if me > 0:
		var above: Dictionary = ladder[me - 1]
		v.add_child(Style.rich("[color=#c09f86]Next:[/color] <%s> at %d, [color=#%s]%d more[/color] to pass them." % [above["name"],
			above["score"], pc, above["score"] - total + 1], 14))
	else:
		v.add_child(Style.rich("[color=#ffd700]<Lumens> leads the Horde![/color]", 16))
	v.add_child(HSeparator.new())
	v.add_child(Style.label("Prestige per raid boss", 17, Style.C["gold"], true))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	for head in ["Raid", "Boss", "Last boss", "Full clear"]:
		grid.add_child(Style.label(head, 13, Style.C["muted"]))
	for raid in Raids.LIST:
		var locked := Game.raid_unlocked(raid) != ""
		var col: Color = Style.C["dim"] if locked else Style.C["text"]
		grid.add_child(Style.label(raid["name"], 14, col))
		for n in [Prestige.for_boss(raid, false), Prestige.for_boss(raid, true), Prestige.for_clear(raid)]:
			var l := Style.label(str(n), 14, col if locked else Style.C["prestige"])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			grid.add_child(l)
	v.add_child(grid)
	if Game.level() < Balance.MAX_LEVEL:
		v.add_child(Style.label("Raids open at level 60.", 13, Style.C["dim"]))
	return p


func _ladder() -> Control:
	var p := _card()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Style.vbox(2)
	var sc := Style.scroll(v)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(sc)
	var ladder := Prestige.ladder(Game.prestige_total())
	for i in ladder.size():
		var e: Dictionary = ladder[i]
		var row := PanelContainer.new()
		var bg := Color(0.3, 0.2, 0.05, 0.6) if e["you"] else (Color(0.12, 0.05, 0.03, 0.7) if i % 2 == 0 else Color(0, 0, 0, 0))
		row.add_theme_stylebox_override("panel", Style.box(bg, Style.C["gold"] if e["you"] else Color.TRANSPARENT, 1 if e["you"] else 0, 4, 5))
		var h := Style.hbox(10)
		row.add_child(h)
		var rank_col: Color = MEDALS[i] if i < MEDALS.size() else Style.C["muted"]
		var rl := Style.label("#%d" % (i + 1), 16, rank_col, true)
		rl.custom_minimum_size.x = 48
		h.add_child(rl)
		var nl := Style.label("<%s>" % e["name"], 16, Style.C["gold"] if e["you"] else Style.C["text"], e["you"])
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nl)
		h.add_child(Style.label("%d" % e["score"], 16, Style.C["prestige"]))
		v.add_child(row)
	return p


func _card() -> PanelContainer:
	return Style.panel(Color(0.14, 0.06, 0.04, 0.92), Color("6a2414"), 2, 12)
