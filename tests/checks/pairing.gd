extends RefCounted

## Vérifie que chaque fichier satellite a encore son fichier source.
##
## C'est le piège du déménagement à la main : `mv` déplace le `.gd` et laisse
## son `.gd.uid` derrière. Godot regénère alors un identifiant neuf, et les
## références `uid://` des scènes — 170 dans ce dépôt — désignent le vide.
## Même mécanique pour les `.import` des quelque 1 300 assets.

const Files := preload("res://tests/lib/files.gd")


func run(_tree: SceneTree, report) -> void:
	var orphans := 0
	orphans += _check_satellites(report, ".uid")
	orphans += _check_satellites(report, ".import")
	_report_scripts_without_uid(report)
	if orphans == 0:
		report.ok("pairing", "aucun .uid ni .import orphelin")


func _check_satellites(report, extension: String) -> int:
	var orphans := 0
	for satellite in Files.list_files(extension):
		var source := satellite.trim_suffix(extension)
		if not FileAccess.file_exists(source):
			report.fail("pairing", "%s existe, mais pas %s" % [satellite, source])
			orphans += 1
	return orphans


## Un script sans `.uid` n'est pas cassé — Godot en créera un au prochain
## import. C'est signalé, pas compté en échec.
func _report_scripts_without_uid(report) -> void:
	var without_uid := []
	for script in Files.list_files(".gd"):
		if not FileAccess.file_exists(script + ".uid"):
			without_uid.append(script)
	if not without_uid.is_empty():
		report.note("%d script(s) sans .uid — lancer `make import`" % without_uid.size())
