# 15 — Le déplacement

## Objectif

La première vraie règle : déplacer un joueur, avec zones de tackle, esquive et
course. C'est elle qui met à l'épreuve les cartes 13 et 14 sur un cas réel.

## La décision : une commande = un pas vers une case adjacente

Le noyau **n'invente jamais de chemin**. Il arbitre le pas qu'on lui soumet.

Trois raisons, et la troisième est la plus importante :

- **Le chemin compte.** Passer par la gauche ou par la droite change les
  esquives à tenter, et on veut parfois délibérément la route risquée pour finir
  collé à quelqu'un. « Va en (14,6) » est une commande sous-spécifiée.
- **Un chemin calculé par le noyau serait une décision tactique déguisée en
  règle**, et retirerait ce choix aux deux joueurs.
- **L'espace d'actions de l'IA est une carte du terrain** (cf.
  `docs/noyau-et-apprenant.html`) : le réseau désigne une case, pas une suite de
  cases. Le pas atomique est la seule unité que les deux commandeurs — humain et
  réseau — peuvent former de la même façon.

Le client humain garde son aide au tracé (`movement_range.gd`), qui décompose un
clic en pas. **Hors du noyau.**

Coût assumé : les épisodes sont longs, ~1 600 décisions par match. Le chiffre
était déjà celui sur lequel l'infrastructure d'entraînement a été dimensionnée.

## Le contenu

- Le capital de mouvement (MA) et sa consommation, un point par pas.
- **Foncer** : deux pas au-delà du MA, chacun sur 2+, échec = chute.
- **Les zones de tackle** : les huit cases autour d'un adversaire debout.
- **L'esquive** : quitter une zone de tackle exige un jet, cible dérivée de
  l'AG, modifiée par les zones de tackle de la case d'arrivée.
- **La chute** et le revirement qui s'ensuit — le revirement lui-même relève de
  la carte 18, ici on émet l'événement.

## Ce qui met les cartes précédentes à l'épreuve

- Un jet d'esquive raté **doit** ouvrir un état d'attente : la relance d'équipe
  se décide là (carte 14).
- Chaque esquive consomme un d6 de la réserve (carte 13), et deux exécutions du
  même scénario doivent rendre la même suite de résultats.

## Les épreuves à faire échouer d'abord

- Un pas hors du terrain, sur une case occupée, ou sans capital restant est
  refusé, et l'état ne bouge pas.
- Une esquive ratée sans relance disponible produit la chute — et la même graine
  reproduit exactement le même échec.
- Sortir d'une zone de tackle exige un jet ; s'y déplacer sans en sortir, non.

## Terminé quand

- [ ] un joueur se déplace pas à pas, capital consommé correctement ;
- [ ] esquive et course jettent les bons dés, avec les bons modificateurs ;
- [ ] un jet raté ouvre un état d'attente pour la relance ;
- [ ] le même scénario rejoué à graine égale donne le même résultat ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
