# 13 — Les réserves de dés

## Objectif

Le noyau tire ses dés **d'avance**, par type, depuis la graine du match. Une
partie devient rejouable à l'identique, et une suite de dés devient une donnée
qu'on peut lire, écrire à la main, et comparer.

## La décision : une réserve par type de dé, extensible

À la construction, `Dice::new(seed)` déroule **six** suites depuis la graine :

| Réserve | Faces | Pré-tirage | Ce qu'elle sert |
|---|---|---|---|
| d3 | 3 | 100 | distance de déviation, avec la compétence du botteur |
| d6 | 6 | 10 000 | esquive, course, ramassage, armure, blessure, distance |
| dé de blocage | 6 | 100 | résultat d'un blocage |
| d8 | 8 | 100 | direction de déviation |
| d12 | 12 | 100 | sélection d'un joueur aligné au hasard |
| d16 | 16 | 100 | table des Prières à Nuffle |

**Six et non cinq** : la phase 2 a trouvé le d3 dans le dépôt, sur la compétence
du botteur — *« le ballon ne dévie que de D3 cases plutôt que les D6
habituels »*. Il ne figurait dans aucune liste.

**Et `Dice::new` et non `Match::new`** : `Match` est le livrable de la carte 14.
La carte 13, écrite avant, s'y référait — contradiction relevée en phase 1. Les
dés sont autonomes ; la carte 14 les branchera.

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

- [x] `Dice::new(seed)` construit les six réserves ;
- [x] l'extension est vue équivalente à un pré-tirage plus large ;
- [x] deux processus rendent la même empreinte, dés compris ;
- [x] une réserve se construit à la main pour un test ;
- [x] `make test-behaviour`, `make check-arch`, `make check-integrity`,
  `make check-mutations` passent.


---

# Ce que la carte a appris

## Une seule graine, six flux — et ce n'était pas la conception prévue

La proposition initiale était une fonction `seed_for(graine, type)`, à écrire et
à tester. Elle a été remplacée par le **paramètre de flux de ChaCha** : la graine
du match est la clé, chaque type de dé est un numéro de flux. L'indépendance des
six suites devient une propriété de l'algorithme au lieu d'être une propriété de
notre code.

Le gain n'est pas seulement d'écrire moins. Une dérivation « la i-ème graine pour
le i-ème type » aurait eu un piège : **insérer un septième dé au milieu de la
liste aurait décalé la graine de tous les suivants**, invalidant d'un coup tous
les journaux enregistrés. Avec des numéros de flux fixes, un nouveau type prend
le 6 et ne perturbe rien.

Mesuré avant d'être écrit, sur `rand_chacha` 0.9 :

| | |
|---|---|
| Graines voisines (0, 1, 2, 42, 43), même flux | suites sans rapport |
| Uniformité, 6 000 000 de d6 | chaque face à moins de 0,06 % du million attendu |
| Coïncidences entre deux flux, 100 000 tirages | 16 808, pour 16 667 attendus — 1,2 écart-type |

Ce dernier chiffre corrige une formulation du départ : on ne peut pas demander
que les suites n'aient **jamais** la même valeur. Deux suites indépendantes de 1
à 6 coïncident une fois sur six. Ce qui est garanti, c'est l'indépendance, pas la
distinction.

## La clé est construite à la main

`ChaCha8Rng::from_seed` reçoit une clé de 32 octets bâtie ici, plutôt que
`seed_from_u64` qui l'étend par SplitMix64. Cette expansion est une commodité de
`rand_core`, pas une partie de l'algorithme ChaCha : un journal ne dépend donc
que d'un algorithme publié. La clé est majoritairement nulle, sans conséquence —
vérifié ci-dessus.

## L'exigence de couverture a dicté la conception, deux fois

Le rejet du haut de l'intervalle supprime le biais de modulo. Mais sa branche ne
se produit qu'**une fois sur un milliard** à travers un vrai générateur : elle
serait à jamais non couverte, et l'exigence de 100 % aurait poussé à renoncer au
rejet plutôt qu'à mieux concevoir.

D'où deux séparations, la seconde apprise à mes dépens :

1. `face_from(raw, faces) -> Option<u8>` est une **fonction pure**. Son cas de
   rejet se teste en l'appelant avec `u32::MAX`.
2. `draw_with(source, faces)` prend **la source des tirages en paramètre**, et
   non le générateur. J'avais d'abord écrit qu'elle « n'ajoutait aucune ligne
   qu'un test ne parcourt » ; `make check-arch` a répondu 144 sur 145, la
   manquante étant précisément le retour de boucle.

La leçon est celle que le `README` du noyau annonçait : *une ligne devenue
incouvrable est le premier signe que quelque chose d'extérieur s'est invité*.
L'intrus était le générateur, et la règle a servi de détecteur de conception
plutôt que de contrainte à contourner.

## La mutation a trouvé un défaut, pas seulement un test manquant

Six mutations de `face_from` faisaient tourner la boucle de rejet **à l'infini**.
Elles étaient détectées — mais en vingt secondes de délai d'attente chacune, ce
qui faisait passer `make check-mutations` de 2 secondes à 2 minutes.

Le vrai motif de la correction n'est pas la vitesse des tests. **Une boucle de
rejet non bornée peut figer une partie pour toujours**, et au milieu d'une nuit
d'auto-jeu, un plantage bruyant vaut mieux qu'un processus qui ne rend plus la
main. La boucle est bornée à 64 tentatives — un rejet arrivant une fois sur un
milliard, soixante-quatre d'affilée n'arriveront jamais. C'est une alarme, pas un
réglage. Retour à 6 secondes.

Aucune autre vérification n'aurait posé cette question.

## Trois mutants survivent, et c'est une preuve

`Die::prealloc` remplacée par 0, par 1, ou privée de son cas du d6 : les tests
restent verts. C'est **normal**. La réserve se prolonge toute seule, donc la
taille du pré-tirage n'est observable par aucun appelant — ce qui est exactement
la propriété que cette carte devait démontrer.

Ces mutants survivent *parce que la conception est juste*. Les tuer demanderait
un test affirmant `prealloc() == 10_000` : un test d'une constante de réglage, à
corriger à chaque ajustement, qui ne protégerait rien. Exclus dans
`app/core/kernel/.cargo/mutants.toml`, avec ce raisonnement écrit dedans.

**Une exclusion de mutation se justifie, elle ne se subit pas.** Celle-ci dit
qu'un réglage de performance n'est pas un comportement.

## Un piège de l'outil de couverture, qui resservira

La première version bornée finissait par `panic!` en queue de fonction. La
couverture est retombée à 99,33 % — et le rapport ligne à ligne, lui, ne montrait
**aucune ligne rouge**. Ni le HTML, ni le texte, ni le LCOV n'indiquaient de
ligne à zéro ; seul le résumé comptait 97 lignes sur 98.

Une **queue divergente produit une ligne fantôme dans le résumé** de
`cargo llvm-cov`. Réécrite en une seule expression, la fonction repasse à 100 % :

```rust
(0..TENTATIVES_MAX)
    .find_map(|_| face_from(raw(), faces))
    .expect("tirages bruts tous rejetés : la source n'est pas uniforme")
```

Une demi-heure perdue à interroger l'outil. Le raccourci, la prochaine fois :
**si le résumé désigne une ligne que le rapport détaillé ne montre pas, chercher
une queue divergente.**

## Ce qui reste ouvert, et pour qui

- **La réserve de déroulé (A5)** n'est aujourd'hui garantie que par l'absence de
  `Clone` sur `Dice`. C'est un garde-fou, pas une implémentation : c'est la
  carte 14 qui devra nommer l'opération de fork.
- **Deux inconnues de règles**, notées mais hors périmètre : ce que fait un 12
  quand l'équipe a moins de onze joueurs alignés, et ce que « relancez les
  doublons » signifie pour le d16. Elles appartiennent aux cartes qui useront de
  ces dés.
- **La table des symboles du dé de blocage** est sourcée mais s'applique en
  carte 16, mise à jour en conséquence. Le noyau ne connaît que des nombres.
