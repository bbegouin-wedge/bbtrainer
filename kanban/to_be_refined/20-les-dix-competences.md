# 20 — Les dix compétences et leurs points d'accroche

## Objectif

Poser la mécanique par laquelle une compétence s'insère dans la résolution, puis
en implémenter dix. Les cent une suivantes doivent alors coûter un fichier
chacune.

## La décision : des points d'accroche nommés

La résolution émet des étapes nommées — `AvantJetEsquive`, `ResultatBlocage`,
`ApresChute`, `AvantJetArmure`… — et chaque compétence s'y branche. Ajouter une
compétence est un fichier, pas une édition du cœur.

**À une condition expresse : l'ordre d'application est explicite.** Blood Bowl
dit qui choisit l'ordre quand deux compétences se disputent le même moment. Un
ordre implicite — celui de l'enregistrement, celui du masque de bits — serait un
bogue silencieux, et le pire genre : le jeu tournerait, et se tromperait.

L'alternative écartée — consulter `has(BLOCAGE)` directement dans la résolution
— se lit comme le livre de règles et rend l'ordre évident. Mais la fonction de
blocage finirait à trois cents lignes, ce que la règle des vingt lignes de
`CLAUDE.md` interdit de toute façon.

## L'encodage, déjà décidé

Les 111 compétences tiennent dans un **`u128` par joueur**. Le noyau peut donc
les **représenter toutes** en n'en **implémentant que dix**, et l'observation du
réseau les voit toutes pour le prix d'un entier. On entraîne sur dix sans que
l'encodage soit à refaire.

## Questions ouvertes

- **Lesquelles dix ?** Il faut celles qui changent la tactique, pas les plus
  faciles. Blocage, Esquive, Plaquage, Garde, Réception, Bras supplémentaires
  sont des candidates évidentes ; les quatre autres sont à discuter.
- **La liste des points d'accroche** : elle ne s'invente pas, elle se relève sur
  les dix compétences retenues, puis se vérifie sur un échantillon des cent
  autres — sinon on aura conçu pour dix cas.
- **Une compétence peut-elle ouvrir un état d'attente ?** Oui (« veux-tu
  utiliser Blocage acrobatique ? »), et ça change la signature des accroches.
- **`skills_fr.json` porte déjà les 111**, avec catégorie et type. Le noyau
  lit-il ce fichier — ce qu'il ne peut pas, il n'a pas d'E/S — ou reçoit-il les
  compétences injectées par la liaison ?

## Terminé quand

- [ ] les points d'accroche existent, avec un ordre d'application explicite ;
- [ ] dix compétences sont implémentées et testées, une par une ;
- [ ] deux compétences qui se disputent le même moment sont couvertes ;
- [ ] ajouter une onzième est un fichier, démontré ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
