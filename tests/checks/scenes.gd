extends RefCounted

## Charge, instancie et fait vivre une frame à chacune des scènes du dépôt.
##
## Le chargement seul ne suffit pas : il résout les références mais n'exécute
## aucun `_ready()`. C'est l'instanciation qui attrape un script cassé, un
## `@export` vidé par un déplacement, ou un nœud attendu et absent.

const Fichiers := preload("res://tests/lib/fichiers.gd")


func executer(arbre: SceneTree, rapport) -> void:
	var scenes := Fichiers.lister(".tscn")
	for chemin in scenes:
		await _verifier(arbre, rapport, chemin)
	rapport.note("%d scène(s) chargée(s) et instanciée(s)" % scenes.size())


func _verifier(arbre: SceneTree, rapport, chemin: String) -> void:
	var packed := ResourceLoader.load(chemin) as PackedScene
	if packed == null:
		rapport.ko("scène", "%s ne se charge pas" % chemin)
		return
	var noeud := packed.instantiate()
	if noeud == null:
		rapport.ko("scène", "%s ne s'instancie pas" % chemin)
		return
	await _faire_vivre(arbre, noeud)
	rapport.ok("scène", chemin)


func _faire_vivre(arbre: SceneTree, noeud: Node) -> void:
	arbre.root.add_child(noeud)
	await arbre.process_frame
	noeud.queue_free()
	await arbre.process_frame
