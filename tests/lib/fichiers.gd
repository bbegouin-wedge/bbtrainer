extends RefCounted

## Parcours du dépôt : liste les fichiers d'une extension donnée.
##
## `addons/` est exclu — son code ne nous appartient pas et ses erreurs ne sont
## pas les nôtres. `.godot/` l'est aussi : c'est du cache régénérable.

const IGNORES := ["res://addons", "res://.godot", "res://.git", "res://.claude", "res://.idea"]


static func lister(extension: String, racine := "res://") -> Array[String]:
	var trouves: Array[String] = []
	_parcourir(racine, extension, trouves)
	trouves.sort()
	return trouves


static func _parcourir(chemin: String, extension: String, trouves: Array[String]) -> void:
	if _ignore(chemin):
		return
	var dossier := DirAccess.open(chemin)
	if dossier == null:
		return
	dossier.list_dir_begin()
	var entree := dossier.get_next()
	while entree != "":
		_visiter(chemin, entree, dossier.current_is_dir(), extension, trouves)
		entree = dossier.get_next()
	dossier.list_dir_end()


static func _visiter(
	parent: String, entree: String, est_dossier: bool, extension: String, trouves: Array[String]
) -> void:
	var complet := parent.path_join(entree)
	if est_dossier:
		_parcourir(complet, extension, trouves)
	elif entree.ends_with(extension):
		trouves.append(complet)


static func _ignore(chemin: String) -> bool:
	for prefixe in IGNORES:
		if chemin.begins_with(prefixe):
			return true
	return false


## Lit un fichier texte du dépôt, chaîne vide s'il est illisible.
static func lire(chemin: String) -> String:
	var f := FileAccess.open(chemin, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()
