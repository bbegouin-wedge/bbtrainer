extends RefCounted

## Charge chaque script du dépôt.
##
## Un script non attaché à une scène — composant, autoload, utilitaire — n'est
## vu par aucune autre vérification. Une erreur de syntaxe ou un `preload` mort
## y dort jusqu'à la première exécution, c'est-à-dire jusqu'à l'utilisateur.

const Files := preload("res://tests/lib/files.gd")


func run(_tree: SceneTree, report) -> void:
	var scripts := Files.list_files(".gd")
	for path in scripts:
		_check(report, path)
	report.note("%d script(s) chargé(s)" % scripts.size())


func _check(report, path: String) -> void:
	if ResourceLoader.load(path) == null:
		report.fail("scripts", "%s ne se charge pas" % path)
	else:
		report.ok("scripts", path)
