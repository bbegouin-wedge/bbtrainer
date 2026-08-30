# 18 — Le tour et le revirement

## Objectif

Donner une fin à la partie. Sans structure de tour, rien de ce que produisent
les cartes 15 à 17 ne se conclut — et sans conclusion, aucun signal
d'apprentissage.

## Le contenu

- **L'activation** : un joueur agit une fois par tour, et l'ordre est libre.
- **Les actions par tour** : un blitz, une passe, une transmission, une
  agression — chacune une fois.
- **Le revirement** : ce qui met fin au tour immédiatement.
- **Le compte des tours** : 8 par équipe et par mi-temps, 16 en tout.
- **Le touchdown**, le score, et la remise en jeu qui suit.
- **La mi-temps** et le changement de camp.

## Pourquoi c'est la carte qui décide de la forme de la récompense

`docs/noyau-et-apprenant.html` fait reposer tout l'apprentissage sur un signal
rare et tardif : le résultat du match. C'est ici qu'il naît. Les frontières de
tour sont aussi les seuls instants où une position **a un sens à évaluer** — le
stratège n'appelle la fonction de valeur qu'à ces instants-là.

L'événement de fin de tour n'est donc pas un détail de comptage : c'est le point
d'ancrage de la moitié de l'infrastructure d'IA.

## Questions ouvertes

- **La liste exacte des revirements** : chute du joueur actif, ballon perdu,
  passe ratée, temps écoulé… à établir contre le livre de règles, pas de
  mémoire.
- **L'horloge de tour** existe-t-elle ? Elle n'a aucun sens en auto-jeu et un
  vrai sens en jeu humain.
- **Les joueurs à terre et sonnés** : se relever coûte du mouvement, un sonné se
  relève au tour suivant. Où vit cet état — carte 11 ?
- **La fin de match** : prolongations, jet de pièce, coup de pied. Hors
  périmètre, mais à nommer.

## Terminé quand

- [ ] un match entier se joue du premier tour au seizième ;
- [ ] les revirements interrompent le tour au bon moment ;
- [ ] un touchdown marque, la partie reprend, le score tient ;
- [ ] un événement de fin de tour est émis, exploitable par le stratège ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
