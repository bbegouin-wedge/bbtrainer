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
## Le banc : ce qu'une équipe engage en dehors de ses joueurs. Les relances ne
## figurent pas dans allowedStaff — toute équipe y a droit, à son propre coût.
enum Staff { REROLLS, APOTHECARY, CHEERLEADERS, COACH_ASSISTANTS }

## Correspondance avec les clés de allowedStaff dans teams_fr.json.
const STAFF_KEYS := {
	Staff.APOTHECARY: "APOTHECARY",
	Staff.CHEERLEADERS: "CHEERLEADERS",
	Staff.COACH_ASSISTANTS: "COACH_ASSISTANTS",
}
const STAFF_MAX := {
	Staff.REROLLS: 8,
	Staff.APOTHECARY: 1,
	Staff.CHEERLEADERS: 12,
	Staff.COACH_ASSISTANTS: 12,
}
const STAFF_ORDER := [
	Staff.REROLLS, Staff.APOTHECARY, Staff.CHEERLEADERS, Staff.COACH_ASSISTANTS,
]

const DUGOUT_LOCATIONS := [Location.RESERVES, Location.KO, Location.INJURED]

signal roster_changed
signal entry_location_changed(entry: Entry, from: Location, to: Location)
signal staff_changed


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



var _entries: Array[Entry] = []
## Effectifs de banc par équipe, et l'équipe engagée de chaque côté — c'est elle
## qui dit quel staff est autorisé.
var _staff: Dictionary = {}
var _teams: Dictionary = {}


## Construit l'effectif du match depuis l'équipe composée. Tout le monde commence
## en réserve : le terrain est vide tant que le coach n'a rien placé.
func build_from_team_state() -> void:
	_entries.clear()
	_staff.clear()
	_teams.clear()
	_teams[Team.BLUE] = TeamState.getSelectedTeam()
	var number := 1
	for player: BloodBowlData.Player in TeamState.get_expanded_team():
		_entries.append(Entry.new(number, Team.BLUE, player))
		number += 1
	for star: BloodBowlData.StarPlayer in TeamState._champions_list.values():
		_entries.append(Entry.new(number, Team.BLUE, null, star))
		number += 1
	roster_changed.emit()


func get_team(team: Team) -> BloodBowlData.Team:
	return _teams.get(team, null)


## Les relances sont toujours permises ; le reste dépend de allowedStaff.
func is_staff_allowed(team: Team, kind: Staff) -> bool:
	if kind == Staff.REROLLS:
		return get_team(team) != null
	var roster := get_team(team)
	if roster == null:
		return false
	return STAFF_KEYS[kind] in roster.allowed_staff


func get_staff(team: Team, kind: Staff) -> int:
	return _staff.get(team, {}).get(kind, 0)


func set_staff(team: Team, kind: Staff, value: int) -> void:
	if not is_staff_allowed(team, kind):
		return
	var clamped := clampi(value, 0, int(STAFF_MAX[kind]))
	if get_staff(team, kind) == clamped:
		return
	if not _staff.has(team):
		_staff[team] = {}
	_staff[team][kind] = clamped
	staff_changed.emit()


func add_staff(team: Team, kind: Staff, delta: int) -> void:
	set_staff(team, kind, get_staff(team, kind) + delta)


static func staff_label(kind: Staff) -> String:
	match kind:
		Staff.REROLLS: return "Relances"
		Staff.APOTHECARY: return "Apothicaire"
		Staff.CHEERLEADERS: return "Pom-pom girls"
		Staff.COACH_ASSISTANTS: return "Assistants"
	return ""


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
	_staff.clear()
	_teams.clear()
	roster_changed.emit()
	staff_changed.emit()


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
