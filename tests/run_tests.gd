extends SceneTree

## Harnais d'intégrité — `make check-integrity`.
##
## Ce n'est pas encore une suite de tests unitaires : c'est un filet, destiné à
## rendre sûr le déménagement vers l'organisation cible (cf. CLAUDE.md). Il
## vérifie que rien ne s'est cassé, pas que le jeu est juste. Les tests de
## règles viendront s'ajouter ici quand `core/` existera.
##
## Sortie 0 si tout passe, 1 sinon.

const VERIFICATIONS := {
	"projet": "res://tests/checks/projet.gd",
	"appariement": "res://tests/checks/appariement.gd",
	"classes": "res://tests/checks/classes.gd",
	"scripts": "res://tests/checks/scripts.gd",
	"ressources": "res://tests/checks/ressources.gd",
	"donnees": "res://tests/checks/donnees.gd",
	"scenes": "res://tests/checks/scenes.gd",
	"references": "res://tests/checks/references.gd",
	"assets": "res://tests/checks/assets_donnees.gd",
	"architecture": "res://tests/checks/architecture.gd",
}


func _initialize() -> void:
	var rapport = preload("res://tests/lib/reporter.gd").new()
	for nom in _demandees():
		await _executer(nom, rapport)
	rapport.resume()
	quit(1 if rapport.a_echoue() else 0)


## Sans argument, tout est vérifié. `make check-integrity V=scenes` n'en lance qu'une.
func _demandees() -> Array:
	var demandes := OS.get_cmdline_user_args()
	if demandes.is_empty():
		return VERIFICATIONS.keys()
	var retenues := []
	for nom in demandes:
		if VERIFICATIONS.has(nom):
			retenues.append(nom)
		else:
			push_error("Vérification inconnue : %s" % nom)
	return retenues


func _executer(nom: String, rapport) -> void:
	print("[####] %s" % nom)
	var verification = load(VERIFICATIONS[nom]).new()
	await verification.executer(self, rapport)
