extends RefCounted

## Charge chaque ressource autonome : thèmes, tuiles, shaders.
##
## `global_theme.tres` (1 645 lignes) et les deux TileSet ne sont ouverts par
## aucune scène au démarrage. Une police déplacée ou une texture renommée s'y
## voit à l'écran, pas au lancement.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(_arbre: SceneTree, rapport) -> void:
	var total := 0
	for extension in [".tres", ".gdshader", ".res"]:
		total += _verifier_extension(rapport, extension)
	rapport.note("%d ressource(s) chargée(s)" % total)
	return


func _verifier_extension(rapport, extension: String) -> int:
	var trouves := Fichiers.lister(extension)
	for chemin in trouves:
		if ResourceLoader.load(chemin) == null:
			rapport.ko("ressource", "%s ne se charge pas" % chemin)
		else:
			rapport.ok("ressource", chemin)
	return trouves.size()
