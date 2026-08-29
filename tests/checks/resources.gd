extends RefCounted

## Charge chaque ressource autonome : thèmes, tuiles, shaders.
##
## `global_theme.tres` (1 645 lignes) et les deux TileSet ne sont ouverts par
## aucune scène au démarrage. Une police déplacée ou une texture renommée s'y
## voit à l'écran, pas au lancement.

const Files := preload("res://tests/lib/files.gd")


func run(_tree: SceneTree, report) -> void:
	var total := 0
	for extension in [".tres", ".gdshader", ".res"]:
		total += _check_extension(report, extension)
	report.note("%d ressource(s) chargée(s)" % total)
	return


func _check_extension(report, extension: String) -> int:
	var found := Files.list_files(extension)
	for path in found:
		if ResourceLoader.load(path) == null:
			report.fail("resources", "%s ne se charge pas" % path)
		else:
			report.ok("resources", path)
	return found.size()
