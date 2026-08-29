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

const Fichiers := preload("res://tests/lib/fichiers.gd")
const RACINE := "res://core"


func executer(_arbre: SceneTree, rapport) -> void:
	var fichiers := Fichiers.lister(".gd", RACINE)
	if fichiers.is_empty():
		rapport.note("core/ ne contient aucun script — l'organisation cible n'est pas encore posée")
		return
	var interdits := _noms_interdits()
	for chemin in fichiers:
		_verifier_heritage(rapport, chemin)
		_verifier_dependances(rapport, chemin, interdits)
	rapport.ok("architecture", "%d script(s) de core/ vérifiés" % fichiers.size())


## Le type natif dont hérite le script, quelle que soit la longueur de la
## chaîne d'héritage.
func _verifier_heritage(rapport, chemin: String) -> void:
	var script := ResourceLoader.load(chemin) as GDScript
	if script == null:
		return
	var base := script.get_instance_base_type()
	if ClassDB.is_parent_class(base, "Node"):
		rapport.ko("architecture", "%s hérite de %s : pas de Node dans core/" % [chemin, base])


func _verifier_dependances(rapport, chemin: String, interdits: Dictionary) -> void:
	var texte := Fichiers.lire(chemin)
	_verifier_chemins(rapport, chemin, texte)
	_verifier_identifiants(rapport, chemin, _code_nu(texte), interdits)


## Les chemins vivent dans des chaînes — impossible de retirer les chaînes comme
## pour les identifiants. On saute donc les lignes de commentaire, qui sont le
## seul cas réaliste de chemin cité sans être utilisé.
func _verifier_chemins(rapport, chemin: String, texte: String) -> void:
	var motif := RegEx.create_from_string("res://[^\"'\\s\\)\\],]+")
	for ligne in texte.split("\n"):
		if ligne.strip_edges().begins_with("#"):
			continue
		_verifier_ligne(rapport, chemin, motif, ligne)


func _verifier_ligne(rapport, chemin: String, motif: RegEx, ligne: String) -> void:
	for trouve in motif.search_all(ligne):
		var cite: String = trouve.get_string()
		if not cite.begins_with(RACINE + "/"):
			rapport.ko("architecture", "%s cite %s, hors de core/" % [chemin, cite])


func _verifier_identifiants(rapport, chemin: String, code: String, interdits: Dictionary) -> void:
	for nom in interdits:
		var motif := RegEx.create_from_string("\\b" + nom + "\\b")
		if motif.search(code) != null:
			rapport.ko("architecture", "%s utilise %s (%s)" % [chemin, nom, interdits[nom]])


## Les autoloads, et tous les `class_name` déclarés hors de `core/`.
func _noms_interdits() -> Dictionary:
	var interdits := {}
	for reglage in ProjectSettings.get_property_list():
		var cle: String = reglage["name"]
		if cle.begins_with("autoload/"):
			interdits[cle.trim_prefix("autoload/")] = "autoload"
	_relever_classes_externes(interdits)
	return interdits


func _relever_classes_externes(interdits: Dictionary) -> void:
	var motif := RegEx.create_from_string("(?m)^class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	for chemin in Fichiers.lister(".gd"):
		if chemin.begins_with(RACINE + "/"):
			continue
		var trouve := motif.search(Fichiers.lire(chemin))
		if trouve != null:
			interdits[trouve.get_string(1)] = "class_name déclaré dans " + chemin


## Retire chaînes puis commentaires : un nom cité dans une phrase de
## documentation n'est pas une dépendance. Les chaînes partent en premier, pour
## qu'un `#` à l'intérieur de l'une d'elles n'ouvre pas un faux commentaire.
func _code_nu(texte: String) -> String:
	var sans_chaines := RegEx.create_from_string("\"[^\"\\n]*\"|'[^'\\n]*'").sub(texte, "", true)
	return RegEx.create_from_string("#[^\\n]*").sub(sans_chaines, "", true)
