extends RefCounted

## Vérifie que chaque fichier satellite a encore son fichier source.
##
## C'est le piège du déménagement à la main : `mv` déplace le `.gd` et laisse
## son `.gd.uid` derrière. Godot regénère alors un identifiant neuf, et les
## références `uid://` des scènes — 170 dans ce dépôt — désignent le vide.
## Même mécanique pour les `.import` des quelque 1 300 assets.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(_arbre: SceneTree, rapport) -> void:
	var orphelins := 0
	orphelins += _verifier_satellites(rapport, ".uid")
	orphelins += _verifier_satellites(rapport, ".import")
	_signaler_scripts_sans_uid(rapport)
	if orphelins == 0:
		rapport.ok("appariement", "aucun .uid ni .import orphelin")


func _verifier_satellites(rapport, extension: String) -> int:
	var orphelins := 0
	for satellite in Fichiers.lister(extension):
		var source := satellite.trim_suffix(extension)
		if not FileAccess.file_exists(source):
			rapport.ko("appariement", "%s existe, mais pas %s" % [satellite, source])
			orphelins += 1
	return orphelins


## Un script sans `.uid` n'est pas cassé — Godot en créera un au prochain
## import. C'est signalé, pas compté en échec.
func _signaler_scripts_sans_uid(rapport) -> void:
	var sans := []
	for script in Fichiers.lister(".gd"):
		if not FileAccess.file_exists(script + ".uid"):
			sans.append(script)
	if not sans.is_empty():
		rapport.note("%d script(s) sans .uid — lancer `make import`" % sans.size())
