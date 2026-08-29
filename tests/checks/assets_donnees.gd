extends RefCounted

## Vérifie les chemins d'assets qui vivent dans les JSON de données.
##
## `bloodbowl_data.gd` fait `load("res://" + icon)` : les 452 chemins d'icônes
## sont écrits dans `teams_fr.json` et `star_players_fr.json`, pas dans le code.
## Aucun grep du code ne les voit, et un déplacement de `assets/` les casse tous
## en silence — l'écran de choix d'équipe s'affiche, sans icônes.

const Fichiers := preload("res://tests/lib/fichiers.gd")
const CLES := ["icon", "blue", "red"]
const SOURCES := ["res://data/teams_fr.json", "res://data/star_players_fr.json"]


func executer(_arbre: SceneTree, rapport) -> void:
	var chemins := {}
	for source in SOURCES:
		_collecter(source, chemins)
	for relatif in chemins:
		if not FileAccess.file_exists("res://" + relatif):
			rapport.ko("asset", "%s cité par %s est absent" % [relatif, chemins[relatif]])
	rapport.ok("assets", "%d chemin(s) distincts vérifiés dans les données" % chemins.size())


func _collecter(source: String, chemins: Dictionary) -> void:
	var brut := Fichiers.lire(source)
	if brut.is_empty():
		return
	var donnees = JSON.parse_string(brut)
	_explorer(donnees, source, chemins)


func _explorer(noeud, source: String, chemins: Dictionary) -> void:
	if noeud is Dictionary:
		_explorer_dictionnaire(noeud, source, chemins)
	elif noeud is Array:
		for element in noeud:
			_explorer(element, source, chemins)


func _explorer_dictionnaire(noeud: Dictionary, source: String, chemins: Dictionary) -> void:
	for cle in noeud:
		var valeur = noeud[cle]
		if cle in CLES and valeur is String and not valeur.is_empty():
			chemins[valeur] = source
		else:
			_explorer(valeur, source, chemins)
