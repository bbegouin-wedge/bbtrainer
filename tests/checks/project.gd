extends RefCounted

## Vérifie la configuration du projet elle-même.
##
## `project.godot` désigne la scène principale, les sept autoloads, l'icône :
## autant de chemins qui ne sont cités nulle part ailleurs. Un autoload déplacé
## sans mise à jour du fichier de projet ne casse rien à l'import — il casse le
## démarrage, et rien d'autre ne le verrait.

const Files := preload("res://tests/lib/files.gd")


func run(tree: SceneTree, report) -> void:
	_check_setting(report, "application/run/main_scene")
	_check_setting(report, "application/config/icon")
	_check_autoloads(tree, report)


func _check_setting(report, key: String) -> void:
	var path: String = ProjectSettings.get_setting(key, "")
	if path.is_empty():
		report.fail("project", "%s n'est pas renseigné" % key)
	elif not FileAccess.file_exists(path):
		report.fail("project", "%s désigne %s, absent" % [key, path])
	else:
		report.ok("project", "%s → %s" % [key, path])


## Deux vérifications distinctes : le script existe sur disque, ET le singleton
## a bien été monté sous /root au démarrage.
func _check_autoloads(tree: SceneTree, report) -> void:
	for setting in ProjectSettings.get_property_list():
		var key: String = setting["name"]
		if key.begins_with("autoload/"):
			_check_autoload(tree, report, key.trim_prefix("autoload/"))


func _check_autoload(tree: SceneTree, report, name: String) -> void:
	var declared: String = ProjectSettings.get_setting("autoload/" + name, "")
	var path := declared.trim_prefix("*")
	if not FileAccess.file_exists(path):
		report.fail("project", "autoload %s désigne %s, absent" % [name, path])
	elif tree.root.get_node_or_null(NodePath(name)) == null:
		report.fail("project", "autoload %s n'est pas monté sous /root" % name)
	else:
		report.ok("project", "autoload %s → %s" % [name, path])
