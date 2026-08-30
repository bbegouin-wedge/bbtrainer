# 6 — Éclater `autoload/`

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

## Questions ouvertes

- **Combien de lots ?** Les deux premiers (`scene_orchestrator`, `gui_state`)
  sont des `git mv` purs — ils peuvent partir seuls, tout de suite.
  `blood_bowl_manager`, `match_state` et `team_state` sont des extractions.
- **`MatchState` reste-t-il un autoload** une fois sa donnée dans `core/match/` ?
  Il faudra bien que quelqu'un tienne l'instance courante — un use case, ou un
  autoload mince qui ne fait plus que la porter.
- **`EventBus` survit-il à `use_cases/` ?** L'architecture cible le remplace à
  terme par des commandes et des événements explicites. Le déplacer dans
  `io/bus/` est-il un pas utile, ou un déplacement qu'on défera ?

## Terminé quand

- `autoload/` n'existe plus, `project.godot` ne déclare que les autoloads
  restants ;
- `make check-arch` vérifie un `core/` qui a grossi, sans violation ;
- `make test-behaviour` couvre le comportement de ce qui a été converti ;
- `make run` : le parcours complet, du choix d'équipe au dépôt d'un joueur sur
  le terrain.
