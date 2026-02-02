extends VBoxContainer
signal team_selected(team: BloodBowlData.Team)

func _ready():
	var teams = BloodBowlManager.get_all_teams()
	for t in teams:
		var but = Button.new()
		but.text = t.name
		var texture = load(t.icon)
		if texture is Texture2D:
			# Godot 4 : modifier via ImageTexture
			var image = texture.get_image()
			var new_texture = ImageTexture.create_from_image(image)
			#but.icon = texture
			but.pressed.connect(_on_button_clicked.bind(t.uid))
			but.add_theme_constant_override("icon_max_width", 64)
			but.theme_type_variation = "texturedButton"
		print(t.uid)
		add_child(but)
		
func _on_button_clicked(team_uid: String):
	var team = BloodBowlManager.get_team(team_uid)
	team_selected.emit(team)
	print("%s a été cliqué!" % team_uid)
