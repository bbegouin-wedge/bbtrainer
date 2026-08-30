# 13 — Les réserves de dés

## Objectif

Le noyau tire ses dés **d'avance**, par type, depuis la graine du match. Une
partie devient rejouable à l'identique, et une suite de dés devient une donnée
qu'on peut lire, écrire à la main, et comparer.

## La décision : une réserve par type de dé, extensible

À la construction, `Match::new(seed)` déroule cinq suites depuis la graine :

| Réserve | Pré-tirage |
|---|---|
| d6 | 10 000 |
| dé de blocage | 100 |
| d8 | 100 |
| d12 | 100 |
| d16 | 100 |

Consommer un dé, c'est avancer un index. Chaque réserve garde **son générateur à
côté** : si un match dépasse, on prolonge la suite, et la valeur obtenue est
exactement celle qu'un pré-tirage plus large aurait donnée. Il n'y a donc pas de
plafond, et le comportement en fin de réserve n'est pas un cas particulier.

**Le dé de blocage est un type à part entière.** Six faces, mais des symboles en
proportions inégales : le dériver d'un d6 ferait que chaque blocage décale la
suite des jets d'esquive et d'armure.

## Ce que ce découpage achète

- **Reproductibilité** — même graine, mêmes réserves, même partie à commandes
  égales. C'est ce que `docs/noyau-et-apprenant.html` fonde sur le journal.
- **Cloisonnement par type** — ajouter une règle qui consomme un d8 ne décale
  pas la suite des d6. Les types ne se contaminent plus.
- **Lisibilité au test** — une réserve se fabrique à la main : « donne-moi
  1, 1, 6, 6 » devient un test de règle trivial à écrire et à relire.
- **Vitesse** — un index qui avance, pas un appel de générateur. Sur des
  millions de parties, ça se mesure.

Ce que ça n'achète **pas**, et il faut l'écrire : à l'intérieur d'un type, le
décalage subsiste. Une règle qui consomme un d6 de plus au tour 2 décale tous
les d6 suivants de ce match. Un corpus rejoué après un changement de règle
montrera du bruit après le point de divergence.

## Deux points de mise en œuvre

**Les fonctions de dés s'écrivent à la main.** `ChaCha8Rng` garantit la
stabilité de son **flux brut** entre versions, pas celle des distributions de
`rand` : `gen_range` peut changer d'implémentation et casser tous les journaux
en silence. `d6()`, `two_d6()`, `block_die()` se dérivent de `next_u32()`, en
vingt lignes qui nous appartiennent.

**Le stratège ne doit jamais puiser dans la réserve du match.** Quand il
déroulera cinq intentions (cf. `docs/noyau-et-apprenant.html`), il clonera
l'état — donc l'index de réserve. Les déroulés verraient **les dés qui vont
réellement sortir**, et l'agent choisirait le plan qui gagne avec ceux-là : il
jouerait en connaissant l'avenir. Rien ne l'exige encore, mais l'API doit rendre
la faute impossible dès maintenant — une réserve de déroulé se dérive d'une
graine de déroulé, jamais de celle du match.

## Le dimensionnement, et d'où il vient

~350 activations par match, 1 à 3 d6 chacune (esquive, foncer, ramasser,
armure, blessure), plus engagements et météo : **environ 1 100 d6 pour un match
ordinaire, jusqu'à 3 000 pour un match très violent**. Les 10 000 laissent trois
à neuf fois de marge — et l'extension paresseuse rend le chiffre non critique.

## Les épreuves à faire échouer d'abord

- **La reproductibilité** : deux processus, même graine, même empreinte de
  réserve. C'est le contrôle de la carte 12, réutilisé — et il doit rougir si on
  sème le générateur autrement.
- **L'extension est transparente** : consommer 10 001 d6 rend la même suite
  qu'un pré-tirage de 20 000. À vérifier, pas à supposer.
- **Le cloisonnement** : consommer des d8 ne change aucun d6 tiré ensuite.

## Terminé quand

- [ ] `Match::new(seed)` construit les cinq réserves ;
- [ ] l'extension est vue équivalente à un pré-tirage plus large ;
- [ ] deux processus rendent la même empreinte, et l'inverse a été vu échouer ;
- [ ] une réserve se construit à la main pour un test ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
