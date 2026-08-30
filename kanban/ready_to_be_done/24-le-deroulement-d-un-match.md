# 24 — Le déroulement d'un match

## Objectif

Faire de `legal_commands()` une fonction de **l'endroit où l'on en est**.

Aujourd'hui il rend `[EndTurn, Ask]` en toutes circonstances, comme si un match
était toujours en cours de jeu. Or placer un joueur n'est légal qu'au placement,
déplacer qu'en tour, et rien ne l'est entre les deux. C'est un mensonge que la
carte 14 pouvait se permettre — elle n'avait qu'une commande — et que la première
carte de règles ne pourra plus.

**Elle passe devant la carte 15**, qui écrirait sinon la légalité du déplacement
dans le vide, et la réécrirait ensuite.

## La première version de cette carte était fausse

Elle a été écrite avant la passe de conception, et
`docs/domaine-de-blood-bowl.html` l'a démentie sur trois points. Ils sont
consignés ici parce qu'ils expliquent la forme retenue.

**Elle volait le mot « Phase »** pour nommer sa machine à états. Dans le livre de
règles, *Phase* désigne autre chose de précis : la période entre un coup d'envoi
et un touchdown.

**Elle ignorait le round.** Le compteur de tours de la carte 14 est un `u32`
plat, qui ne correspond à rien.

**Et surtout, elle supposait un emboîtement qui n'existe pas.**

## Le temps a deux découpages, et ils ne s'emboîtent pas

> *« Chaque mi-temps comprend huit rounds, et chaque round est composé de deux
> tours, un pour chaque Coach. Ceci signifie qu'au fil d'un match, il y aura deux
> mi-temps, seize rounds et trente-deux tours : seize pour chaque Coach. »*
> — livre de règles, p. 28

> *« Une **Phase** est la période de jeu entre le moment où une équipe engage et
> celui où l'une des deux équipes marque, ou la fin de la mi-temps. Ceci signifie
> que la longueur d'une Phase n'est jamais fixée ; certaines durent toute une
> mi-temps, tandis que d'autres ne peuvent durer qu'un seul round, voire un seul
> tour ! »* — p. 28

Le premier découpage est régulier et compté. Le second ne l'est pas : ses
frontières tombent **à l'intérieur** d'un round, puisqu'un touchdown peut arriver
à n'importe quel moment.

Une énumération imbriquée ne peut donc pas porter les deux. C'est la contrainte
centrale de cette carte.

## Le nom : `Drive`, et jamais `Phase`

La collision n'existe qu'en français. Le terme anglais officiel pour ce que le
livre appelle *Phase* est **drive** — et le code de ce projet est en anglais
(cf. `CLAUDE.md`, « Langue »).

Donc : `Drive` pour le concept du domaine, et **le mot `Phase` ne s'emploie nulle
part dans le code**, y compris pour autre chose. Un développeur qui lit le livre
français en parallèle le mésinterpréterait.

## Ce que le déroulement doit représenter, tout sourcé

| | Règle | Source |
|---|---|---|
| Deux mi-temps de huit rounds, deux tours par round | 32 tours, 16 par Coach | p. 28 |
| La séquence de début de drive a **trois** étapes | Placement, Coup d'Envoi, Événement de Coup d'Envoi | p. 30 |
| **La défense place en premier** | *« En commençant par l'équipe qui engage »* — et chaque Coach place ses onze d'un bloc, ce n'est pas une alternance | p. 30 |
| **L'attaque joue en premier** | *« L'équipe qui a réceptionné le ballon au début de la mi-temps aura le premier Tour, suivie par l'équipe qui a engagé »* | p. 32 |
| À la mi-temps, les rôles s'inversent | *« l'équipe qui a réceptionné au début de la première mi-temps deviendra l'équipe qui engage »* | p. 32 |
| Après un touchdown, celui qui a marqué engage | *« l'équipe qui a marqué le Touchdown engagera en bottant le ballon à l'adversaire avant que le Tour suivant commence »* | p. 32 |
| Un drive finit sur un touchdown **ou** la fin de la mi-temps | | p. 28 |

Noter l'inversion : **on place dans un ordre et on joue dans l'autre.** C'est
exactement le genre de détail qu'on aurait écrit à l'envers de mémoire.

## Le périmètre : le squelette, pas le contenu

La carte pose les étapes et leurs transitions. Elle ne pose **aucune** des règles
qui vivent dedans :

| Étape | Ce que cette carte en fait | Qui la remplit |
|---|---|---|
| Placement | l'ordre défense puis attaque, et « j'ai fini » | carte 22 (le roster), carte 19 (les règles de placement) |
| Coup d'envoi | une transition | carte 19 |
| Événement de coup d'envoi | une transition | carte 19 |
| Jeu | l'alternance, le compte des rounds, le passage de main | cartes 15 à 18 |
| Mi-temps | l'inversion des rôles | carte 19 |
| Fin de match | la sortie | carte 18 |

C'est la carte 14 d'un étage au-dessus : une forme, une commande triviale qui
traverse chaque étape, et les vraies qui arrivent ensuite.

## Ce que la carte ne couvre pas

Aucun joueur n'est placé : le placement n'aura qu'une commande, « j'ai fini ».
Placer exige un roster, qui est la carte 22. Aucun ballon n'est botté, aucun dé
n'est consommé, aucun touchdown ne peut être marqué — la fin d'un drive ne
s'atteint donc que par l'épuisement des rounds.

L'échafaudage `Ask` / `Answer` / `Confirm` de la carte 14 reste en place : cette
carte ne produit toujours aucune vraie question. La carte 16 le remplace.

**Et le module `roll`** — la machinerie de jet que la passe a révélée — n'est pas
ici. Cette carte ne jette aucun dé.

## Terminé quand

- [ ] le mot `Phase` n'apparaît nulle part dans le code ;
- [ ] les deux découpages du temps sont représentés **séparément**, et un
  touchdown au milieu d'un round est représentable ;
- [ ] `legal_commands()` dépend de l'étape, et le prouve : ce qui est légal en
  tour ne l'est pas au placement, et réciproquement ;
- [ ] la défense place en premier, l'attaque joue en premier, et les deux sont
  vérifiés — c'est l'inversion qu'on écrirait à l'envers ;
- [ ] les rôles s'inversent à la mi-temps ;
- [ ] un match traverse tout le cycle jusqu'à `Finished` sans sauter d'étape ;
- [ ] le compteur de tour plat de la carte 14 a disparu ;
- [ ] la carte 19 est mise à jour de ce qu'elle hérite ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity`,
  `make check-mutations` passent.
