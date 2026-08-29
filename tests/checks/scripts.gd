extends RefCounted

## Charge chaque script du dépôt.
##
## Un script non attaché à une scène — composant, autoload, utilitaire — n'est
## vu par aucune autre vérification. Une erreur de syntaxe ou un `preload` mort
## y dort jusqu'à la première exécution, c'est-à-dire jusqu'à l'utilisateur.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(_arbre: SceneTree, rapport) -> void:
	var scripts := Fichiers.lister(".gd")
	for chemin in scripts:
		_verifier(rapport, chemin)
	rapport.note("%d script(s) chargé(s)" % scripts.size())


func _verifier(rapport, chemin: String) -> void:
	if ResourceLoader.load(chemin) == null:
		rapport.ko("script", "%s ne se charge pas" % chemin)
	else:
		rapport.ok("script", chemin)
