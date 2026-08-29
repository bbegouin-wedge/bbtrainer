extends RefCounted

## Vérifie l'unicité des `class_name`.
##
## GDScript n'a pas d'espace de noms : un `class_name` est global au projet.
## Deux fichiers qui déclarent le même nom se disputent l'enregistrement, et
## c'est le dernier importé qui gagne — silencieusement. Le risque devient réel
## dès qu'on duplique un fichier pour le déplacer au lieu de le déplacer.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(_arbre: SceneTree, rapport) -> void:
	var declarations := {}
	for chemin in Fichiers.lister(".gd"):
		_relever(chemin, declarations)
	for nom in declarations:
		_verifier(rapport, nom, declarations[nom])
	rapport.ok("classes", "%d class_name distincts" % declarations.size())


func _relever(chemin: String, declarations: Dictionary) -> void:
	var motif := RegEx.create_from_string("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var trouve := motif.search(Fichiers.lire(chemin))
	if trouve == null:
		return
	var nom := trouve.get_string(1)
	if not declarations.has(nom):
		declarations[nom] = []
	declarations[nom].append(chemin)


func _verifier(rapport, nom: String, fichiers: Array) -> void:
	if fichiers.size() > 1:
		rapport.ko("classes", "class_name %s déclaré %d fois : %s" % [nom, fichiers.size(), ", ".join(fichiers)])
