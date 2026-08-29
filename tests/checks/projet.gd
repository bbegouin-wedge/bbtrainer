extends RefCounted

## Vérifie la configuration du projet elle-même.
##
## `project.godot` désigne la scène principale, les sept autoloads, l'icône :
## autant de chemins qui ne sont cités nulle part ailleurs. Un autoload déplacé
## sans mise à jour du fichier de projet ne casse rien à l'import — il casse le
## démarrage, et rien d'autre ne le verrait.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(arbre: SceneTree, rapport) -> void:
	_verifier_reglage(rapport, "application/run/main_scene")
	_verifier_reglage(rapport, "application/config/icon")
	_verifier_autoloads(arbre, rapport)


func _verifier_reglage(rapport, cle: String) -> void:
	var chemin: String = ProjectSettings.get_setting(cle, "")
	if chemin.is_empty():
		rapport.ko("projet", "%s n'est pas renseigné" % cle)
	elif not FileAccess.file_exists(chemin):
		rapport.ko("projet", "%s désigne %s, absent" % [cle, chemin])
	else:
		rapport.ok("projet", "%s → %s" % [cle, chemin])


## Deux vérifications distinctes : le script existe sur disque, ET le singleton
## a bien été monté sous /root au démarrage.
func _verifier_autoloads(arbre: SceneTree, rapport) -> void:
	for reglage in ProjectSettings.get_property_list():
		var cle: String = reglage["name"]
		if cle.begins_with("autoload/"):
			_verifier_autoload(arbre, rapport, cle.trim_prefix("autoload/"))


func _verifier_autoload(arbre: SceneTree, rapport, nom: String) -> void:
	var declare: String = ProjectSettings.get_setting("autoload/" + nom, "")
	var chemin := declare.trim_prefix("*")
	if not FileAccess.file_exists(chemin):
		rapport.ko("projet", "autoload %s désigne %s, absent" % [nom, chemin])
	elif arbre.root.get_node_or_null(NodePath(nom)) == null:
		rapport.ko("projet", "autoload %s n'est pas monté sous /root" % nom)
	else:
		rapport.ok("projet", "autoload %s → %s" % [nom, chemin])
