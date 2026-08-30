# 14 — Commandes, événements, et l'état d'attente

## Objectif

Poser la forme que prend un match dans le noyau : `Match::submit(Command)` rend
`Vec<Event>`, `legal_commands()` dit ce qui est jouable, et le noyau sait
**s'interrompre pour poser une question**.

Cette carte ne contient **aucune règle de jeu**. Elle n'existe que pour fixer le
vocabulaire, avec une seule commande triviale — `FinDeTour` — pour prouver que
la chaîne tient.

## La décision : le noyau est interruptible

La plupart des règles de Blood Bowl demandent l'accord d'un coach en cours de
résolution : quel dé de blocage retenir, dans quelle direction pousser, suivre
ou non, et surtout **utiliser une relance d'équipe après un jet raté**.

Le noyau s'arrête donc et passe en **état d'attente de décision**.
`legal_commands()` ne rend alors que les réponses possibles. Le flux reste
uniforme : toujours `submit(commande) → événements`, pour l'humain comme pour
l'IA.

Les deux alternatives écartées, et pourquoi :

- **Pré-déclarer les réponses dans la commande** (« bloque, et relance si ça
  rate ») est strictement moins expressif : à Blood Bowl on décide de relancer
  **en voyant** le résultat et ce qu'il a coûté.
- **Une politique par défaut dans le noyau** lui ferait porter une décision de
  jeu, et retirerait au joueur une de ses vraies compétences.

Conséquence pour l'IA : le masque de légalité contient les choix de dé et de
relance, donc l'agent **apprend** la gestion des relances au lieu de la subir.

## Ce que la forme impose à l'état

- **Sérialisable à tout instant**, y compris en pleine attente de décision.
  C'est ce qui rend le journal possible et la reprise exacte.
- **Clonable**, parce que le stratège devra dérouler des tours qui n'ont pas
  lieu. Le coût du clone n'est pas critique aujourd'hui ; il le deviendra, et
  c'est une raison de garder l'état plat.
- **Aucune référence de nœud**, déjà acquis avec `UnitId`.

## Ce que la carte 13 lui lègue

**`Dice` n'est pas `Clone`, délibérément.** Un `#[derive(Clone)]` sur `Match` ne
compilera donc pas, et c'est voulu : c'est le garde-fou de A5. Le stratège
clonera un jour l'état pour dérouler des tours qui n'ont pas lieu, et s'il en
clonait les dés, ses simulations verraient **les dés qui vont réellement
sortir** — il jouerait en connaissant l'avenir, sans que rien ne le signale.

Cette carte doit donc **nommer l'opération de copie** plutôt que la dériver :

```rust
/// Le seul moyen d'obtenir un état pour un déroulé : copie tout, sauf les dés,
/// qu'il refait depuis une graine de déroulé.
fn fork_for_rollout(&self, rollout_seed: u64) -> Self
```

La carte 13 ne fournit que l'empêchement ; l'implémentation est ici.

**`Dice::new(seed)` existe et est autonome.** La carte 13 s'était écrite autour
d'un `Match::new(seed)` qui n'existait pas encore. C'est cette carte qui branche
les dés dans l'état de partie.

**L'annulation d'un tour n'a pas besoin de cloner.** Les curseurs des réserves
sont des index : on les note et on les repose. Rien ne l'exerce encore, donc rien
ne l'implémente — la couverture le signalerait, et ce serait juste.

## Rapport à la carte 11

La carte 11 (« Extraire l'état de partie ») demande où va le contenu de
`match_state.gd` et s'il passe en Rust directement. **Cette carte-ci répond à sa
question de forme** : elle crée le réceptacle. La carte 11 devient le
déménagement du contenu dedans, et ses questions ouvertes se referment.

À mettre à jour dans la foulée.

## Les épreuves à faire échouer d'abord

- Une commande illégale est **refusée** sans muter l'état — et l'état d'après un
  refus est identique à celui d'avant, octet pour octet.
- En attente de décision, `legal_commands()` ne rend **que** les réponses
  attendues, et aucune commande ordinaire.
- L'état se sérialise et se relit en pleine attente, et le match reprend au même
  point.

## Terminé quand

- [ ] `Command`, `Event`, `Match::submit()`, `legal_commands()` existent ;
- [ ] l'état d'attente est représenté explicitement, pas déduit ;
- [ ] `FinDeTour` traverse toute la chaîne ;
- [ ] la sérialisation en attente est vue tenir ;
- [ ] la carte 11 est mise à jour ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
