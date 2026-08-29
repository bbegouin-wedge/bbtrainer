extends RefCounted

## Analyse chaque JSON du dépôt.
##
## Les règles du jeu — 30 équipes, 111 compétences, 63 stars — vivent dans ces
## fichiers. Une virgule de trop les rend illisibles, et `load_from_json` se
## contente alors de retourner faux : le jeu démarre, vide.

const Files := preload("res://tests/lib/files.gd")


func run(_tree: SceneTree, report) -> void:
	var files := Files.list_files(".json")
	for path in files:
		_check(report, path)
	report.note("%d fichier(s) de données analysés" % files.size())


func _check(report, path: String) -> void:
	var parser := JSON.new()
	var raw := Files.read(path)
	if raw.is_empty():
		report.fail("json", "%s est illisible ou vide" % path)
		return
	if parser.parse(raw) != OK:
		report.fail("json", "%s ligne %d : %s" % [path, parser.get_error_line(), parser.get_error_message()])
		return
	report.ok("json", path)
