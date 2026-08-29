extends RefCounted

## Vérifie l'unicité des `class_name`.
##
## GDScript n'a pas d'espace de noms : un `class_name` est global au projet.
## Deux fichiers qui déclarent le même nom se disputent l'enregistrement, et
## c'est le dernier importé qui gagne — silencieusement. Le risque devient réel
## dès qu'on duplique un fichier pour le déplacer au lieu de le déplacer.

const Files := preload("res://tests/lib/files.gd")


func run(_tree: SceneTree, report) -> void:
	var declarations := {}
	for path in Files.list_files(".gd"):
		_collect_declaration(path, declarations)
	for name in declarations:
		_check(report, name, declarations[name])
	report.ok("classes", "%d class_name distincts" % declarations.size())


func _collect_declaration(path: String, declarations: Dictionary) -> void:
	var pattern := RegEx.create_from_string("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var match := pattern.search(Files.read(path))
	if match == null:
		return
	var name := match.get_string(1)
	if not declarations.has(name):
		declarations[name] = []
	declarations[name].append(path)


func _check(report, name: String, files: Array) -> void:
	if files.size() > 1:
		report.fail("classes", "class_name %s déclaré %d fois : %s" % [name, files.size(), ", ".join(files)])
