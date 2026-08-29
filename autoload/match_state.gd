extends Node

## Où se trouve chaque joueur pendant un match.
##
## Distinct de TeamState, qui ne concerne que la composition d'équipe avant match.
## Ici le joueur est une donnée : sa représentation change selon l'endroit —
## un nœud Unit sur le terrain, une vignette de GUI dans un dugout.
##
## Les boîtes du dugout ne sont pas des lieux mais des états : mettre un joueur
## en KO, c'est changer sa localisation, pas le déplacer dans le monde.

enum Location { RESERVES, PITCH, KO, INJURED }
## Côté du terrain. Seul BLUE a un effectif aujourd'hui ; RED existe pour que les
## vues sachent déjà quoi filtrer le jour où la seconde équipe arrivera.
enum Team { BLUE, RED }
## État d'un joueur sur le terrain. Rien ne le pilote encore — c'est le bandeau
## de joueurs qui le donne à lire, en attendant les règles de tour.
enum Condition { READY, PLAYED, PRONE, STUNNED }

const DUGOUT_LOCATIONS := [Location.RESERVES, Location.KO, Location.INJURED]

signal roster_changed
signal entry_location_changed(entry: Entry, from: Location, to: Location)


class Entry:
	extends RefCounted

	var number: int
	var team: Team = Team.BLUE
	var location: Location = Location.RESERVES
	var condition: Condition = Condition.READY
	## Présence sur le terrain ; nulle partout ailleurs.
	var unit: Node = null

	var _player: BloodBowlData.Player
	var _star: BloodBowlData.StarPlayer

	func _init(number_: int, team_: Team, player: BloodBowlData.Player = null,
			star: BloodBowlData.StarPlayer = null) -> void:
		number = number_
		team = team_
		_player = player
		_star = star

	func get_player() -> BloodBowlData.Player:
		return _player

	func get_star() -> BloodBowlData.StarPlayer:
		return _star

	func is_star() -> bool:
		return _star != null

	func get_display_name() -> String:
		if _star:
			return _star.name
		return _player.position_name if _player else "?"

	func get_icon() -> Texture2D:
		if _star:
			return _star.get_blue_icon_texture()
		return _player.get_blue_icon_texture() if _player else null


var _entries: Array[Entry] = []


## Construit l'effectif du match depuis l'équipe composée. Tout le monde commence
## en réserve : le terrain est vide tant que le coach n'a rien placé.
func build_from_team_state() -> void:
	_entries.clear()
	var number := 1
	for player: BloodBowlData.Player in TeamState.get_expanded_team():
		_entries.append(Entry.new(number, Team.BLUE, player))
		number += 1
	for star: BloodBowlData.StarPlayer in TeamState._champions_list.values():
		_entries.append(Entry.new(number, Team.BLUE, null, star))
		number += 1
	roster_changed.emit()


func get_entries() -> Array[Entry]:
	return _entries


## `team` à -1 pour ne pas filtrer par équipe.
func get_entries_at(location: Location, team: int = -1) -> Array[Entry]:
	var result: Array[Entry] = []
	for entry in _entries:
		if entry.location == location and (team == -1 or entry.team == team):
			result.append(entry)
	return result


func count_at(location: Location, team: int = -1) -> int:
	return get_entries_at(location, team).size()


func set_location(entry: Entry, location: Location) -> void:
	if entry.location == location:
		return
	var previous := entry.location
	entry.location = location
	entry_location_changed.emit(entry, previous, location)
	roster_changed.emit()


func get_entry_for_unit(unit: Node) -> Entry:
	for entry in _entries:
		if entry.unit == unit:
			return entry
	return null


func clear() -> void:
	_entries.clear()
	roster_changed.emit()


func set_condition(entry: Entry, condition: Condition) -> void:
	if entry.condition == condition:
		return
	entry.condition = condition
	roster_changed.emit()


static func condition_label(condition: Condition) -> String:
	match condition:
		Condition.READY: return "Prêt"
		Condition.PLAYED: return "Joué"
		Condition.PRONE: return "À terre"
		Condition.STUNNED: return "Sonné"
	return ""


static func location_label(location: Location) -> String:
	match location:
		Location.RESERVES:
			return "Réserves"
		Location.KO:
			return "K.O."
		Location.INJURED:
			return "Blessés"
		Location.PITCH:
			return "Terrain"
	return ""
