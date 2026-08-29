extends RefCounted

## Base d'un cas de test : assertions, collecte des échecs, nettoyage.
##
## Chaque fichier de `tests/unit/` en hérite et déclare des méthodes `test_*`.
## Le lanceur les découvre par réflexion — rien à inscrire dans une liste, donc
## rien à oublier d'y inscrire.

var failures: Array[String] = []

## Posé par le lanceur. Nul pour un test unitaire qui n'en a pas besoin ;
## indispensable à un test d'intégration, qui doit monter une scène.
var tree: SceneTree = null

var _current := ""
var _tracked: Array[Object] = []


func begin(test_name: String) -> void:
	_current = test_name


## Les objets suivis sont libérés après chaque test. Un Node créé hors de
## l'arbre n'est libéré par personne : sans ça, chaque test fuit.
func track(object: Object) -> Object:
	_tracked.append(object)
	return object


## Un RefCounted se libère seul et refuse `free()` — seuls les Object non
## comptés (les Node, ici) sont à libérer à la main.
func cleanup() -> void:
	for object in _tracked:
		if is_instance_valid(object) and not object is RefCounted:
			if object is Node and (object as Node).is_inside_tree():
				(object as Node).get_parent().remove_child(object)
			object.free()
	_tracked.clear()


## Monte une scène, lui laisse une frame pour vivre, et la libère au nettoyage.
func mount(scene_path: String) -> Node:
	var node := (load(scene_path) as PackedScene).instantiate()
	tree.root.add_child(node)
	await tree.process_frame
	track(node)
	return node


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s : %s" % [_current, message])


func equals(actual, expected, message: String) -> void:
	check(actual == expected, "%s — attendu %s, obtenu %s" % [message, expected, actual])


func is_null(value, message: String) -> void:
	check(value == null, "%s — attendu null, obtenu %s" % [message, value])


func is_true(value: bool, message: String) -> void:
	check(value, message)


func is_false(value: bool, message: String) -> void:
	check(not value, message)
