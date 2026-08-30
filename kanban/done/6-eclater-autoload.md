# 6 — Éclater `autoload/` : les déplacements purs

## Objectif

`autoload/` est le dernier répertoire de code hors de l'architecture cible. Ses
sept scripts n'ont **pas la même destination** : les répartir, et supprimer
celui qui ne sert plus.

## Pourquoi ce n'est pas un déplacement en bloc

Le test « qui s'en sert aujourd'hui ? » donne une réponse unanime — tous sont
consommés par des sous-dossiers du client — et c'est précisément ce qui le rend
trompeur : **le client est la seule couche qui existe**. `core/` porte deux
fichiers, `use_cases/` aucun.

Le test qui discrimine est celui de `docs/noyau-et-adaptateurs.html` : **qui
suit l'autorité le jour où elle passe côté serveur ?**

| Script | Destination | Pourquoi |
|---|---|---|
| `scene_orchestrator.gd` | `io/client/bootstrap/` | navigue entre écrans — client |
| `gui_state.gd` | `io/client/bootstrap/` | état du curseur — client |
| `event_bus.gd` | `io/bus/` | la couture entre couches, pas un organe de l'écran |
| `blood_bowl_manager.gd` | `io/persistence/` **et** `core/` | lit les JSON *et* indexe le catalogue : deux métiers dans 97 lignes |
| `match_state.gd` | `core/match/` | où se trouve chaque joueur — **l'autorité serveur arbitrerait là-dessus** |
| `team_state.gd` | `core/` + un use case | composition d'équipe — domaine |
| `game_status_manager.gd` | **supprimé** | doublon mort de `SceneOrchestrator` |

Mettre `match_state` dans `io/client/` serait le placement le plus coûteux à
défaire : c'est l'état de la partie, exactement ce qu'un serveur possédera.

## Le cas `game_status_manager`

L'audit l'a relevé (faille 6) : `_changeStatus()` n'est jamais appelé, son
signal `onStateChanged` n'a aucun abonné, et seule son énumération sert encore —
depuis deux fichiers. Il ne fait que refléter passivement `SceneOrchestrator`.

L'énumération déménage dans `SceneOrchestrator`, qui décide déjà des
transitions, et l'autoload disparaît de `project.godot`.

## Ce qui rend l'affaire délicate

**Un autoload est un singleton global.** Le sortir de `project.godot`, c'est
retirer un nom du champ lexical de tout le projet : chaque `MatchState.…` du
code devient une erreur de compilation. Bonne nouvelle — c'est bruyant, pas
silencieux. Mauvaise — ça ne se fait pas fichier par fichier.

`match_state.gd` et `team_state.gd` demandent la même manœuvre que la carte 1 :
caractériser d'abord (`tests/unit/`), convertir ensuite, et un test
d'intégration pour le câblage que les tests unitaires ne voient pas.

## Ce que ce lot fait, et ce qu'il laisse

La carte s'est resserrée sur ce qui est un **déplacement** : trois autoloads
changent de dossier, un quatrième disparaît. Les trois restants —
`blood_bowl_manager`, `match_state`, `team_state` — demandent des extractions et
ont leurs propres cartes (10 et 11).

| Script | Fait |
|---|---|
| `scene_orchestrator.gd` | → `app/io/client/bootstrap/` |
| `gui_state.gd` | → `app/io/client/bootstrap/` |
| `event_bus.gd` | → `app/io/bus/` |
| `game_status_manager.gd` | **supprimé** |

## Le risque d'ordre de chargement, levé par la mesure

`event_bus.gd` déclare `signal game_phase_changed(new_phase: …GameStatus)` — une
annotation **résolue à l'analyse**. Or `EventBus` est déclaré **avant**
`SceneOrchestrator` dans `project.godot`, alors que `GameStatusManager` l'était
avant. Le repli était prêt : un `class_name GamePhase` visible quel que soit
l'ordre.

Il n'a pas servi. **Aucune erreur d'analyse** : GDScript résout le type d'un
autoload par le registre de classes, pas par l'ordre d'instanciation. L'énumération
a donc pu rejoindre `SceneOrchestrator`, qui décide déjà des transitions.

## Le doublon mort

L'audit avait vu juste, et le code le confirme mot pour mot : `_changeStatus()`
jamais appelé, `onStateChanged` sans abonné, `getCurrentStatus()` sans appelant,
et un `currentState` qui ne fait que refléter `EventBus.game_phase_changed` sans
que personne ne le lise. Seule l'énumération vivait encore, citée par quatre
fichiers.

## Terminé quand

- [x] les trois scripts sont à leur place cible, `project.godot` à jour ;
- [x] `game_status_manager.gd` n'existe plus, aucune trace de `GameStatusManager` ;
- [x] les trois vérifications passent — 129, deux de moins, l'autoload mort en
  moins ;
- [x] `make run` : parcours contrôlé à l'écran, zéro erreur au journal.
