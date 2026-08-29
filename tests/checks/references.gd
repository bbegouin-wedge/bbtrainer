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

const Files := preload("res://tests/lib/files.gd")
const SOURCES := [".tscn", ".tres", ".gd", ".godot"]


func run(_tree: SceneTree, report) -> void:
	var files := _sources()
	var pattern_res := RegEx.create_from_string("res://[^\"'\\s\\)\\],]+")
	var pattern_uid := RegEx.create_from_string("uid://[a-z0-9]+")
	var pattern_dyn := RegEx.create_from_string("\"res://\"")
	var counters := {"res": 0, "uid": 0, "dyn": 0}
	for path in files:
		var text := Files.read(path)
		_check_paths(report, path, pattern_res.search_all(text), counters)
		_check_uids(report, path, pattern_uid.search_all(text), counters)
		counters["dyn"] += pattern_dyn.search_all(text).size()
	_conclude(report, files.size(), counters)


func _sources() -> Array[String]:
	var files: Array[String] = ["res://project.godot"]
	for extension in [".tscn", ".tres", ".gd"]:
		files.append_array(Files.list_files(extension))
	return files


func _check_paths(report, source: String, found: Array, counters: Dictionary) -> void:
	for m in found:
		var target: String = m.get_string()
		if not _looks_like_a_path(target):
			continue
		counters["res"] += 1
		if not _exists(target):
			report.fail("references", "%s cite %s, qui n'existe pas" % [source, target])


## Écarte ce qui ressemble à un chemin sans en être un : les expressions
## régulières de ce fichier même, et les préfixes concaténés à l'exécution.
## Ces caractères n'apparaissent dans aucun chemin du dépôt.
func _looks_like_a_path(target: String) -> bool:
	for forbidden_char in ["\\", "[", "]", "^", "*", "?", "`", "+", "%"]:
		if target.contains(forbidden_char):
			return false
	return target.length() > "res://".length()


## `has_id()` ne suffit pas : le registre conserve l'ancien chemin d'un fichier
## disparu et répond vrai. C'est la résolution du chemin qui dit la vérité.
func _check_uids(report, source: String, found: Array, counters: Dictionary) -> void:
	for m in found:
		var text: String = m.get_string()
		counters["uid"] += 1
		var id := ResourceUID.text_to_id(text)
		if not ResourceUID.has_id(id):
			report.fail("references", "%s cite %s, non enregistré" % [source, text])
		elif not FileAccess.file_exists(ResourceUID.get_id_path(id)):
			report.fail(
				"references",
				"%s cite %s → %s, absent" % [source, text, ResourceUID.get_id_path(id)]
			)


func _exists(target: String) -> bool:
	return (
		FileAccess.file_exists(target)
		or DirAccess.dir_exists_absolute(target)
		or ResourceLoader.exists(target)
	)


func _conclude(report, file_count: int, counters: Dictionary) -> void:
	report.ok(
		"references",
		(
			"%d res:// et %d uid:// vérifiés dans %d fichier(s)"
			% [counters["res"], counters["uid"], file_count]
		)
	)
	if counters["dyn"] > 0:
		report.note(
			(
				"%d chemin(s) construits à l'exécution (\"res://\" + variable) : "
				+ "non vérifiables ici, couverts par la vérification des assets de données"
			)
			% counters["dyn"]
		)
