extends RefCounted

## Collecte le verdict des vérifications et met en forme le rapport.
##
## Toute ligne destinée au rapport est préfixée : la sortie de Godot en headless
## contient 199 lignes d'erreurs moteur préexistantes (TileSet, shader) qu'on ne
## peut ni supprimer ni confondre avec un échec. Le préfixe est ce qui permet au
## Makefile de filtrer sans rien perdre.

var _failures: Array[String] = []
var _total := 0


func ok(check: String, detail: String) -> void:
	_total += 1
	print("[ok]   %s : %s" % [check, detail])


func fail(check: String, detail: String) -> void:
	_total += 1
	_failures.append("%s : %s" % [check, detail])
	print("[KO]   %s : %s" % [check, detail])


## Information portée au rapport sans verdict — ce qui n'est pas vérifiable.
func note(detail: String) -> void:
	print("[note] %s" % detail)


func has_failures() -> bool:
	return not _failures.is_empty()


func summary() -> void:
	print("[----] %d vérification(s), %d échec(s)" % [_total, _failures.size()])
	for e in _failures:
		print("[KO]   %s" % e)
