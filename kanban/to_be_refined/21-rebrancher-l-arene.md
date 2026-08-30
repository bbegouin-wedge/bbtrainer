# 21 — Rebrancher l'arène sur `Match`

## Objectif

Le jeu redevient jouable. `io/` cesse de porter des bouts de règles et devient
ce que `CLAUDE.md` décrit : une couche qui traduit les clics en commandes et les
événements en animations.

## Ce que ça déplace

| Aujourd'hui | Devient |
|---|---|
| `arena_phase.gd` décide de ce qui est permis | il demande `legal_commands()` |
| `movement_range.gd` calcule la portée | le noyau la calcule, `io/` la trace |
| `drag_and_drop.gd` mute la grille | il soumet une suite de pas |
| les signaux de l'`EventBus` portent l'état | les événements du noyau portent le récit |

## La difficulté réelle : le récit

Le noyau rend une **liste d'événements**, et c'est délibéré — `io/` doit pouvoir
les animer un par un, dans l'ordre, avec des pauses. Un seul pas de déplacement
peut produire « esquive tentée, dé jeté, joueur tombé, armure percée, joueur
sonné, revirement ». Aujourd'hui `io/` réagit à des signaux instantanés ; il
devra jouer une file.

C'est le vrai travail de cette carte, et il n'a rien à voir avec les règles.

## Questions ouvertes

- **L'aide au tracé** (`movement_range.gd`) : le noyau expose-t-il les cases
  atteignables, ou `io/` les recalcule-t-il ? Le noyau doit le savoir de toute
  façon pour l'observation du réseau — donc probablement lui.
- **Qui tient l'instance de `Match` ?** Un autoload mince, ou la scène d'arène ?
  La carte 11 pose la même question pour l'état de partie.
- **L'état d'attente à l'écran** : quand le noyau demande « quel dé ? », quelle
  interface ? Rien n'existe.
- **Les tests de comportement** : cette carte les réécrit tous, puisque le
  câblage change. Les caractériser avant, comme pour la carte 9.

## Terminé quand

- [ ] `make run` : un match complet se joue à l'écran, du coup d'envoi au
  touchdown ;
- [ ] `io/` ne contient plus aucune règle ;
- [ ] les événements du noyau s'animent dans l'ordre, un par un ;
- [ ] les états d'attente sont jouables à la souris ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
