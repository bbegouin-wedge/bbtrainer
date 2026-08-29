extends RefCounted

## Vérifie les chemins d'assets qui vivent dans les JSON de données.
##
## `bloodbowl_data.gd` fait `load("res://" + icon)` : les 452 chemins d'icônes
## sont écrits dans `teams_fr.json` et `star_players_fr.json`, pas dans le code.
## Aucun grep du code ne les voit, et un déplacement de `assets/` les casse tous
## en silence — l'écran de choix d'équipe s'affiche, sans icônes.

const Files := preload("res://tests/lib/files.gd")
const KEYS := ["icon", "blue", "red"]
const SOURCES := ["res://data/teams_fr.json", "res://data/star_players_fr.json"]


func run(_tree: SceneTree, report) -> void:
	var paths := {}
	for source in SOURCES:
		_collect(source, paths)
	for relatif in paths:
		if not FileAccess.file_exists("res://" + relatif):
			report.fail("data_assets", "%s cité par %s est absent" % [relatif, paths[relatif]])
	report.ok("data_assets", "%d chemin(s) distincts vérifiés dans les données" % paths.size())


func _collect(source: String, paths: Dictionary) -> void:
	var raw := Files.read(source)
	if raw.is_empty():
		return
	var data = JSON.parse_string(raw)
	_explore(data, source, paths)


func _explore(node, source: String, paths: Dictionary) -> void:
	if node is Dictionary:
		_explore_dictionary(node, source, paths)
	elif node is Array:
		for element in node:
			_explore(element, source, paths)


func _explore_dictionary(node: Dictionary, source: String, paths: Dictionary) -> void:
	for key in node:
		var value = node[key]
		if key in KEYS and value is String and not value.is_empty():
			paths[value] = source
		else:
			_explore(value, source, paths)
