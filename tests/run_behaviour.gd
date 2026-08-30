extends SceneTree

## Lanceur des tests de comportement — `make test-behaviour`.
##
## Distinct de run_tests.gd : celui-ci vérifie que le code répond juste, l'autre
## que le dépôt tient. Ils partagent le format de rapport, donc le même filtre
## d'affichage côté Makefile.
##
## Deux dossiers, deux portées : `tests/unit/` pour la logique seule,
## `tests/integration/` pour ce qui exige un arbre de scènes — le câblage, que
## nul test unitaire ne voit. L'arbre est passé au cas de test qui le demande.
##
## Les méthodes `test_*` sont découvertes par réflexion : aucune liste à tenir,
## donc aucun test qu'on oublie d'y inscrire.

const Files := preload("res://tests/lib/files.gd")
const DIRECTORIES := ["res://tests/unit", "res://tests/integration"]


func _initialize() -> void:
	var report = preload("res://tests/lib/reporter.gd").new()
	var files := _test_files()
	if files.is_empty():
		report.fail("behaviour", "aucun fichier *_test.gd trouvé — un lanceur qui ne trouve rien n'est pas un succès")
	for path in files:
		await _run_file(path, report)
	report.summary()
	quit(1 if report.has_failures() else 0)


func _test_files() -> Array[String]:
	var files: Array[String] = []
	for directory in DIRECTORIES:
		files.append_array(Files.list_files("_test.gd", directory))
	return files


func _run_file(path: String, report) -> void:
	print("[####] %s" % path.get_file())
	var script := load(path) as GDScript
	if script == null:
		report.fail("behaviour", "%s ne se charge pas" % path)
		return
	for method in _test_methods(script):
		await _run_test(script, method, report)


func _test_methods(script: GDScript) -> Array:
	var names := []
	for method in script.get_script_method_list():
		if method["name"].begins_with("test_"):
			names.append(method["name"])
	names.sort()
	return names


func _run_test(script: GDScript, method: String, report) -> void:
	var case = script.new()
	case.begin(method)
	case.tree = self
	await case.call(method)
	case.cleanup()
	if case.assertions == 0:
		report.fail("behaviour", "%s n'a exécuté aucune assertion — test vide ou interrompu" % method)
	elif case.failures.is_empty():
		report.ok("behaviour", method)
	else:
		for failure in case.failures:
			report.fail("behaviour", failure)
