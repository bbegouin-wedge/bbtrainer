extends GridContainer

func _ready():
	columns = 3
	EventBus.star_selected.connect(_on_star_selected)
	EventBus.star_deselected.connect(_on_star_deselected)

func _on_star_selected(star: BloodBowlData.StarPlayer):
	var panel := ChampionItemFactory.create(star)
	add_child(panel)

func _on_star_deselected(star: BloodBowlData.StarPlayer):
	for child in get_children():
		if child.get_meta("uid") == star.uid:
			child.queue_free()
			return
