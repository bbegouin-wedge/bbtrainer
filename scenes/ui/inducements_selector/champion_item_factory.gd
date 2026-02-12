class_name ChampionItemFactory

const ICON_SIZE := 96
const FONT_PATH := "res://assets/fonts/SedgwickAve-Regular.ttf"

static func create(sp: BloodBowlData.StarPlayer) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 160)
	panel.set_meta("uid", sp.uid)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Icone
	var icon_container := CenterContainer.new()
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = sp.get_blue_icon_texture()
	if tex:
		texture_rect.texture = tex
	icon_container.add_child(texture_rect)
	vbox.add_child(icon_container)

	# Nom
	var label := Label.new()
	var font = load(FONT_PATH)
	label.add_theme_font_override("font", font)
	label.text = sp.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)

	return panel
