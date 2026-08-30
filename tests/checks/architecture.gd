extends RefCounted

## Vérifie que `core/` tient sa promesse : un noyau de règles qui ne connaît
## rien d'autre que lui-même (cf. CLAUDE.md, « Organisation cible »).
##
## Deux interdits, les seuls que la première version couvre :
##
## 1. **Aucun `Node` dans `core/`.** C'est ce qui rend le noyau vérifiable sans
##    fenêtre, donc testable. Le contrôle porte sur le type natif résolu, pas
##    sur le mot écrit après `extends` : un script de core qui hérite d'un autre
##    script de core qui hérite de `Node` est vu.
##
## 2. **`core/` ne cite rien hors de `core/`.** Ni chemin `res://`, ni autoload,
##    ni `class_name` déclaré ailleurs. GDScript n'ayant pas d'espace de noms,
##    rien n'empêche mécaniquement ces appels — c'est ici, et nulle part
##    ailleurs, qu'ils se voient.

const Files := preload("res://tests/lib/files.gd")
const ROOT := "res://app/core"

## Types du moteur qui touchent au disque. Ils sont natifs, donc la règle des
## dépendances de projet ne les voit pas — et pourtant un noyau qui lit un
## fichier n'est plus un noyau. C'est cet interdit qui empêche la séparation
## chargeur / catalogue de se défaire en silence.
const DISK_ACCESS := ["FileAccess", "DirAccess", "ResourceSaver", "ResourceLoader", "ConfigFile"]


func run(_tree: SceneTree, report) -> void:
	var files := Files.list_files(".gd", ROOT)
	if files.is_empty():
		report.note("core/ ne contient aucun script — l'organisation cible n'est pas encore posée")
		return
	var forbidden := _forbidden_names()
	for path in files:
		_check_inheritance(report, path)
		_check_dependencies(report, path, forbidden)
		_check_no_disk_access(report, path)
	report.ok("architecture", "%d script(s) de core/ vérifiés" % files.size())


## Le type natif dont hérite le script, quelle que soit la longueur de la
## chaîne d'héritage.
func _check_inheritance(report, path: String) -> void:
	var script := ResourceLoader.load(path) as GDScript
	if script == null:
		return
	var base := script.get_instance_base_type()
	if ClassDB.is_parent_class(base, "Node"):
		report.fail("architecture", "%s hérite de %s : pas de Node dans core/" % [path, base])


## Le noyau ignore le disque — cf. docs/noyau-et-apprenant.html.
func _check_no_disk_access(report, path: String) -> void:
	var code := _bare_code(Files.read(path))
	for type_name in DISK_ACCESS:
		if RegEx.create_from_string("\\b" + type_name + "\\b").search(code) != null:
			report.fail(
				"architecture",
				"%s utilise %s : le noyau ne touche pas au disque" % [path, type_name]
			)


func _check_dependencies(report, path: String, forbidden: Dictionary) -> void:
	var text := Files.read(path)
	_check_paths_in(report, path, text)
	_check_identifiers(report, path, _bare_code(text), forbidden)


## Les chemins vivent dans des chaînes — impossible de retirer les chaînes comme
## pour les identifiants. On saute donc les lignes de commentaire, qui sont le
## seul cas réaliste de chemin cité sans être utilisé.
func _check_paths_in(report, path: String, text: String) -> void:
	var pattern := RegEx.create_from_string("res://[^\"'\\s\\)\\],]+")
	for line in text.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		_check_line(report, path, pattern, line)


func _check_line(report, path: String, pattern: RegEx, line: String) -> void:
	for match in pattern.search_all(line):
		var cite: String = match.get_string()
		if not cite.begins_with(ROOT + "/"):
			report.fail("architecture", "%s cite %s, hors de core/" % [path, cite])


func _check_identifiers(report, path: String, code: String, forbidden: Dictionary) -> void:
	for name in forbidden:
		var pattern := RegEx.create_from_string("\\b" + name + "\\b")
		if pattern.search(code) != null:
			report.fail("architecture", "%s utilise %s (%s)" % [path, name, forbidden[name]])


## Les autoloads, et tous les `class_name` déclarés hors de `core/`.
func _forbidden_names() -> Dictionary:
	var forbidden := {}
	for setting in ProjectSettings.get_property_list():
		var key: String = setting["name"]
		if key.begins_with("autoload/"):
			forbidden[key.trim_prefix("autoload/")] = "autoload"
	_collect_external_classes(forbidden)
	return forbidden


func _collect_external_classes(forbidden: Dictionary) -> void:
	var pattern := RegEx.create_from_string("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	for path in Files.list_files(".gd"):
		if path.begins_with(ROOT + "/"):
			continue
		var match := pattern.search(Files.read(path))
		if match != null:
			forbidden[match.get_string(1)] = "class_name déclaré dans " + path


## Retire chaînes puis commentaires : un nom cité dans une phrase de
## documentation n'est pas une dépendance. Les chaînes partent en premier, pour
## qu'un `#` à l'intérieur de l'une d'elles n'ouvre pas un faux commentaire.
func _bare_code(text: String) -> String:
	var without_strings := RegEx.create_from_string("\"[^\"\\n]*\"|'[^'\\n]*'").sub(text, "", true)
	return RegEx.create_from_string("#[^\\n]*").sub(without_strings, "", true)
