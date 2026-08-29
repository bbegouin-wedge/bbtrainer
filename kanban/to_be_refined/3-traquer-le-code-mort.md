# 3 — Traquer le code mort : `make dead-code`

## Objectif

Une cible qui liste les **candidats** au code mort, et qui énonce ses angles
morts. Consultative, jamais bloquante.

## Pourquoi ce n'est pas fiable, et pourquoi c'est quand même utile

Aucune analyse statique ne peut trancher en GDScript, et ce n'est pas un manque
d'outillage — c'est structurel :

- **liaison tardive** : `call("nom")`, `Callable`, `connect` par chaîne,
  `get_node("chemin")` — invisibles à toute passe statique ;
- **les scènes référencent le code par chemin et par UID** : « utilisé » veut
  souvent dire « attaché dans un `.tscn` », pas « importé par du code » ;
- **`class_name` est global** : il n'existe aucun graphe d'imports à parcourir ;
- **les `@export` sont posés dans les scènes** : une variable inutilisée dans le
  code peut être renseignée dans un `.tscn`, et l'inverse — c'est le cas qu'a
  été `use_painted_cells` (carte 2) ;
- **les virtuelles** (`_ready`, `_draw`, `_process`, `_input`) sont appelées par
  le moteur, jamais nommées dans le code.

Ce qui existe déjà : l'éditeur a **Projet → Outils → Explorateur de ressources
orphelines**, mais il ne couvre que les ressources, pas les symboles GDScript.
`gdlint` attrape les variables locales et arguments inutilisés, rien à l'échelle
du projet.

## Ce que la cible peut chercher, par fiabilité décroissante

| Famille | Fiabilité | Méthode |
|---|---|---|
| assets référencés par rien | haute | miroir de la vérification `data_assets` : fichiers moins ceux cités |
| `@export` jamais posé en scène ni assigné en code | haute | exactement `use_painted_cells` |
| signaux jamais émis ni connectés | bonne | `X.emit(`, `.connect(`, `[connection signal=` des `.tscn` |
| script attaché nulle part **et** `class_name` invisible | bonne | croiser les deux axes |
| méthodes jamais appelées | faible | candidats seulement — `call()`, virtuelles, signaux |

**Les deux axes du quatrième point sont obligatoires.** Un `grep` sur le seul
`class_name` a conclu « aucun consommateur » pour `select`, `outline` et
`hoverable` : les trois sont attachés dans `unit.tscn`. Un seul axe suffit à
condamner du code vivant.

## Conception

- **Cible séparée `make dead-code`**, hors de `check-integrity`. Une
  vérification d'intégrité qui rougirait sur un faux positif serait désarmée en
  une semaine.
- **Le rapport énonce ses angles morts à chaque exécution.** Sans ça, un rapport
  vide se lit « pas de code mort » alors qu'il dit « rien que mes greps sachent
  voir ».
- Une famille par fichier dans `tests/deadcode/`, sur le modèle de
  `tests/checks/` — même parcours de dépôt, même format de rapport.

## Ce que la carte ne couvre pas

Elle ne supprime rien. Chaque suppression est une décision, avec sa
vérification exhaustive des consommateurs (règle 4) et ses tests de
caractérisation — comme la carte 2.

## Questions ouvertes

- **Faut-il un fichier d'exemptions** pour les faux positifs connus, ou un
  marqueur dans le code sur le modèle de `arch:no-instrument` ? Un marqueur
  adjacent au code ne dérive pas ; une liste centrale, si.
- **Le rapport doit-il compter** (« 3 candidats ») ou seulement lister ? Un
  compteur invite à le faire tomber à zéro, ce qui n'est pas l'objectif.

## Terminé quand

- `make dead-code` liste les candidats des quatre premières familles ;
- il énonce ses angles morts dans chaque rapport ;
- il retrouve les six signaux morts de l'`EventBus` et le `GameStatusManager`
  relevés par `docs/ossature-de-bbtrainer.html` — c'est son étalonnage.
