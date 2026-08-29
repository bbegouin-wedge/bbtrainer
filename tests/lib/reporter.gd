extends RefCounted

## Collecte le verdict des vérifications et met en forme le rapport.
##
## Toute ligne destinée au rapport est préfixée : la sortie de Godot en headless
## contient 199 lignes d'erreurs moteur préexistantes (TileSet, shader) qu'on ne
## peut ni supprimer ni confondre avec un échec. Le préfixe est ce qui permet au
## Makefile de filtrer sans rien perdre.

var _echecs: Array[String] = []
var _total := 0


func ok(verification: String, detail: String) -> void:
	_total += 1
	print("[ok]   %s : %s" % [verification, detail])


func ko(verification: String, detail: String) -> void:
	_total += 1
	_echecs.append("%s : %s" % [verification, detail])
	print("[KO]   %s : %s" % [verification, detail])


## Information portée au rapport sans verdict — ce qui n'est pas vérifiable.
func note(detail: String) -> void:
	print("[note] %s" % detail)


func a_echoue() -> bool:
	return not _echecs.is_empty()


func resume() -> void:
	print("[----] %d vérification(s), %d échec(s)" % [_total, _echecs.size()])
	for e in _echecs:
		print("[KO]   %s" % e)
