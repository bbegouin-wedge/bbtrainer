extends RefCounted

## Analyse chaque JSON du dépôt.
##
## Les règles du jeu — 30 équipes, 111 compétences, 63 stars — vivent dans ces
## fichiers. Une virgule de trop les rend illisibles, et `load_from_json` se
## contente alors de retourner faux : le jeu démarre, vide.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(_arbre: SceneTree, rapport) -> void:
	var fichiers := Fichiers.lister(".json")
	for chemin in fichiers:
		_verifier(rapport, chemin)
	rapport.note("%d fichier(s) de données analysés" % fichiers.size())


func _verifier(rapport, chemin: String) -> void:
	var analyseur := JSON.new()
	var brut := Fichiers.lire(chemin)
	if brut.is_empty():
		rapport.ko("données", "%s est illisible ou vide" % chemin)
		return
	if analyseur.parse(brut) != OK:
		rapport.ko("données", "%s ligne %d : %s" % [chemin, analyseur.get_error_line(), analyseur.get_error_message()])
		return
	rapport.ok("données", chemin)
