class_name TierBadge
extends Label
## A tier letter (F to SS+) on a chip in the tier's colour. S tiers and above glow.


func _init() -> void:
	custom_minimum_size = Vector2(52, 32)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_type_variation = &"RowCount"
	add_theme_font_size_override("font_size", 18)


func set_tier(tier: int) -> void:
	var color: Color = Fighters.TIERS[tier].color
	text = Fighters.TIERS[tier].name
	var box := StyleBoxFlat.new()
	box.bg_color = color.darkened(0.72)
	box.border_color = color
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.corner_detail = 1
	box.set_content_margin_all(2)
	if tier >= 6:
		box.shadow_color = Color(color, 0.55)
		box.shadow_size = 8
	add_theme_stylebox_override("normal", box)
	add_theme_color_override("font_color", color.lightened(0.15))
