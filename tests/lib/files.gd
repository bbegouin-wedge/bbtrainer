extends RefCounted

## Parcours du dépôt : liste les fichiers d'une extension donnée.
##
## `addons/` est exclu — son code ne nous appartient pas et ses erreurs ne sont
## pas les nôtres. `.godot/` l'est aussi : c'est du cache régénérable.

const IGNORED := ["res://addons", "res://.godot", "res://.git", "res://.claude", "res://.idea"]


static func list_files(extension: String, root := "res://") -> Array[String]:
	var found: Array[String] = []
	_walk(root, extension, found)
	found.sort()
	return found


static func _walk(path: String, extension: String, found: Array[String]) -> void:
	if _is_ignored(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		_visit(path, entry, directory.current_is_dir(), extension, found)
		entry = directory.get_next()
	directory.list_dir_end()


static func _visit(
	parent: String, entry: String, is_directory: bool, extension: String, found: Array[String]
) -> void:
	var full := parent.path_join(entry)
	if is_directory:
		_walk(full, extension, found)
	elif entry.ends_with(extension):
		found.append(full)


static func _is_ignored(path: String) -> bool:
	for prefix in IGNORED:
		if path.begins_with(prefix):
			return true
	return false


## Lit un fichier texte du dépôt, chaîne vide s'il est illisible.
static func read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()
