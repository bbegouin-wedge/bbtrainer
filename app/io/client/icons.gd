class_name Icons
extends RefCounted

## Résolution des chemins d'images en textures.
##
## C'est du client, et de lui seul : charger une `Texture2D` n'a rien à faire
## dans un catalogue de domaine. Les données ne portent qu'un chemin relatif —
## « assets/player_icons/Human/Lineman2B.png » — et ignorent où ce dossier vit
## dans le projet. La racine est ici, en un seul endroit.
##
## Le polymorphisme des icônes vient avec : un joueur en porte une, un duo en
## porte deux, une équipe n'a qu'un chemin nu. C'est de la présentation, pas du
## modèle.

const ASSETS_ROOT := "res://app/io/client/"


## L'écusson d'une équipe.
static func team(a_team) -> Texture2D:
	return _texture(a_team.icon) if a_team else null


## Le jeton bleu d'un joueur ou d'une star. Un duo rend celui du premier.
static func blue(owner) -> Texture2D:
	return _texture(_path_of(owner.icon, "blue")) if owner else null


static func red(owner) -> Texture2D:
	return _texture(_path_of(owner.icon, "red")) if owner else null


## L'icône d'une inscription de match : la star prime sur le joueur.
static func entry(an_entry) -> Texture2D:
	if an_entry == null:
		return null
	return blue(an_entry.get_star()) if an_entry.get_star() else blue(an_entry.get_player())


static func _path_of(icon, field: String) -> String:
	if icon == null:
		return ""
	if icon is Array:
		return _path_of(icon[0], field) if not icon.is_empty() else ""
	return icon.get(field)


static func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(ASSETS_ROOT + path)
