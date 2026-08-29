extends RefCounted

## Charge, instancie et fait vivre une frame à chacune des scènes du dépôt.
##
## Le chargement seul ne suffit pas : il résout les références mais n'exécute
## aucun `_ready()`. C'est l'instanciation qui attrape un script cassé, un
## `@export` vidé par un déplacement, ou un nœud attendu et absent.

const Files := preload("res://tests/lib/files.gd")


func run(tree: SceneTree, report) -> void:
	var scenes := Files.list_files(".tscn")
	for path in scenes:
		await _check(tree, report, path)
	report.note("%d scène(s) chargée(s) et instanciée(s)" % scenes.size())


func _check(tree: SceneTree, report, path: String) -> void:
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		report.fail("scenes", "%s ne se charge pas" % path)
		return
	var node := packed.instantiate()
	if node == null:
		report.fail("scenes", "%s ne s'instancie pas" % path)
		return
	await _bring_to_life(tree, node)
	report.ok("scenes", path)


func _bring_to_life(tree: SceneTree, node: Node) -> void:
	tree.root.add_child(node)
	await tree.process_frame
	node.queue_free()
	await tree.process_frame
