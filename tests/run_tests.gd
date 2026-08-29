extends SceneTree

## Harnais d'intégrité — `make check-integrity`.
##
## Ce n'est pas encore une suite de tests unitaires : c'est un filet, destiné à
## rendre sûr le déménagement vers l'organisation cible (cf. CLAUDE.md). Il
## vérifie que rien ne s'est cassé, pas que le jeu est juste. Les tests de
## règles viendront s'ajouter ici quand `core/` existera.
##
## Sortie 0 si tout passe, 1 sinon.

const CHECKS := {
	"project": "res://tests/checks/project.gd",
	"pairing": "res://tests/checks/pairing.gd",
	"classes": "res://tests/checks/classes.gd",
	"scripts": "res://tests/checks/scripts.gd",
	"resources": "res://tests/checks/resources.gd",
	"json": "res://tests/checks/json.gd",
	"scenes": "res://tests/checks/scenes.gd",
	"references": "res://tests/checks/references.gd",
	"data_assets": "res://tests/checks/data_assets.gd",
	"architecture": "res://tests/checks/architecture.gd",
}


func _initialize() -> void:
	var report = preload("res://tests/lib/reporter.gd").new()
	for name in _requested():
		await _run_check(name, report)
	report.summary()
	quit(1 if report.has_failures() else 0)


## Sans argument, tout est vérifié. `make check-integrity V=scenes` n'en lance qu'une.
func _requested() -> Array:
	var requested := OS.get_cmdline_user_args()
	if requested.is_empty():
		return CHECKS.keys()
	var kept := []
	for name in requested:
		if CHECKS.has(name):
			kept.append(name)
		else:
			push_error("Vérification inconnue : %s" % name)
	return kept


func _run_check(name: String, report) -> void:
	print("[####] %s" % name)
	var check = load(CHECKS[name]).new()
	await check.run(self, report)
