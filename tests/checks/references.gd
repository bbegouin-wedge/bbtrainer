extends RefCounted

## Vérifie que chaque chemin `res://` cité dans le dépôt désigne un fichier
## existant, et que chaque `uid://` est enregistré.
##
## C'est LA vérification du déménagement : un fichier déplacé sans que ses
## références suivent ne casse rien au chargement d'aujourd'hui — il casse
## l'écran qui l'ouvre, un jour, chez l'utilisateur.
##
## Les `uid://` n'ont pas à être réécrits lors d'un déplacement : c'est leur
## raison d'être. Ils cassent en revanche si un `.uid` est déplacé sans son
## script, ou l'inverse — d'où la vérification.

const Fichiers := preload("res://tests/lib/fichiers.gd")
const SOURCES := [".tscn", ".tres", ".gd", ".godot"]


func executer(_arbre: SceneTree, rapport) -> void:
	var fichiers := _sources()
	var motif_res := RegEx.create_from_string("res://[^\"'\\s\\)\\],]+")
	var motif_uid := RegEx.create_from_string("uid://[a-z0-9]+")
	var motif_dyn := RegEx.create_from_string("\"res://\"")
	var compteur := {"res": 0, "uid": 0, "dyn": 0}
	for chemin in fichiers:
		var texte := Fichiers.lire(chemin)
		_verifier_res(rapport, chemin, motif_res.search_all(texte), compteur)
		_verifier_uid(rapport, chemin, motif_uid.search_all(texte), compteur)
		compteur["dyn"] += motif_dyn.search_all(texte).size()
	_conclure(rapport, fichiers.size(), compteur)


func _sources() -> Array[String]:
	var fichiers: Array[String] = ["res://project.godot"]
	for extension in [".tscn", ".tres", ".gd"]:
		fichiers.append_array(Fichiers.lister(extension))
	return fichiers


func _verifier_res(rapport, source: String, trouves: Array, compteur: Dictionary) -> void:
	for m in trouves:
		var cible: String = m.get_string()
		if not _est_un_chemin(cible):
			continue
		compteur["res"] += 1
		if not _existe(cible):
			rapport.ko("référence", "%s cite %s, qui n'existe pas" % [source, cible])


## Écarte ce qui ressemble à un chemin sans en être un : les expressions
## régulières de ce fichier même, et les préfixes concaténés à l'exécution.
## Ces caractères n'apparaissent dans aucun chemin du dépôt.
func _est_un_chemin(cible: String) -> bool:
	for interdit in ["\\", "[", "]", "^", "*", "?", "`", "+", "%"]:
		if cible.contains(interdit):
			return false
	return cible.length() > "res://".length()


## `has_id()` ne suffit pas : le registre conserve l'ancien chemin d'un fichier
## disparu et répond vrai. C'est la résolution du chemin qui dit la vérité.
func _verifier_uid(rapport, source: String, trouves: Array, compteur: Dictionary) -> void:
	for m in trouves:
		var texte: String = m.get_string()
		compteur["uid"] += 1
		var id := ResourceUID.text_to_id(texte)
		if not ResourceUID.has_id(id):
			rapport.ko("référence", "%s cite %s, non enregistré" % [source, texte])
		elif not FileAccess.file_exists(ResourceUID.get_id_path(id)):
			rapport.ko(
				"référence",
				"%s cite %s → %s, absent" % [source, texte, ResourceUID.get_id_path(id)]
			)


func _existe(cible: String) -> bool:
	return (
		FileAccess.file_exists(cible)
		or DirAccess.dir_exists_absolute(cible)
		or ResourceLoader.exists(cible)
	)


func _conclure(rapport, nb_fichiers: int, compteur: Dictionary) -> void:
	rapport.ok(
		"références",
		(
			"%d res:// et %d uid:// vérifiés dans %d fichier(s)"
			% [compteur["res"], compteur["uid"], nb_fichiers]
		)
	)
	if compteur["dyn"] > 0:
		rapport.note(
			(
				"%d chemin(s) construits à l'exécution (\"res://\" + variable) : "
				+ "non vérifiables ici, couverts par la vérification des assets de données"
			)
			% compteur["dyn"]
		)
