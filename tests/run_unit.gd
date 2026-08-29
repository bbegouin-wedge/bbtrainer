extends SceneTree

## Lanceur des tests unitaires — `make test-unit`.
##
## Distinct de run_tests.gd : celui-ci vérifie que le code répond juste, l'autre
## que le dépôt tient. Ils partagent le format de rapport, donc le même filtre
## d'affichage côté Makefile.
##
## Les méthodes `test_*` sont découvertes par réflexion : aucune liste à tenir,
## donc aucun test qu'on oublie d'y inscrire.

const Files := preload("res://tests/lib/files.gd")


func _initialize() -> void:
	var report = preload("res://tests/lib/reporter.gd").new()
	for path in Files.list_files("_test.gd", "res://tests/unit"):
		_run_file(path, report)
	report.summary()
	quit(1 if report.has_failures() else 0)


func _run_file(path: String, report) -> void:
	print("[####] %s" % path.get_file())
	var script := load(path) as GDScript
	if script == null:
		report.fail("unit", "%s ne se charge pas" % path)
		return
	for method in _test_methods(script):
		_run_test(script, method, report)


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
	case.call(method)
	case.cleanup()
	if case.failures.is_empty():
		report.ok("unit", method)
	else:
		for failure in case.failures:
			report.fail("unit", failure)
