extends RefCounted

## Compte les émissions d'un signal. Un simple entier ne suffit pas : il faut un
## objet pour porter la méthode à connecter.

var count := 0


func increment() -> void:
	count += 1
