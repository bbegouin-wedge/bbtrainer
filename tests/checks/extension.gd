extends RefCounted

## Vérifie que la GDExtension Rust est chargée par le moteur.
##
## Pas « le fichier .so existe » — Godot peut le trouver et refuser de
## l'initialiser, et c'est précisément le cas qu'on veut voir. C'est arrivé dès
## le premier essai : gdext visait Godot 4.6 quand le moteur est en 4.5.1.
##
## La classe n'est jamais citée comme identifiant : `BbCore.version()` écrit tel
## quel produirait une erreur de compilation du vérificateur lui-même le jour où
## l'extension ne charge pas, au lieu d'un échec lisible.

const CLASSE := "BbCore"


func run(_tree: SceneTree, report) -> void:
	if not ClassDB.class_exists(CLASSE):
		report.fail("extension", "%s n'est pas enregistrée — la GDExtension ne s'est pas chargée" % CLASSE)
		return
	var instance = ClassDB.instantiate(CLASSE)
	if instance == null:
		report.fail("extension", "%s est déclarée mais ne s'instancie pas" % CLASSE)
		return
	report.ok("extension", "%s chargée, version %s" % [CLASSE, instance.call("version")])
