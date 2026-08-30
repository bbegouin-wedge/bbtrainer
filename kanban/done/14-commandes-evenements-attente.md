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

## Rapport aux cartes 11 et 22

La carte 11 s'est resserrée sur `team_state` pendant ce chantier, et l'état de
match est parti dans la **carte 22**. C'est donc à elle que cette carte répond.

La carte 22 écrivait : *« Le noyau Rust ? Pas tant que `BloodBowlData` est du
GDScript. »* **Cette contrainte n'en était pas une**, et c'est la phase 1 qui l'a
défaite : `docs/noyau-et-apprenant.html` range le catalogue dans les adaptateurs
— *« chargement JSON en lecture seule, injecté dans le noyau plutôt qu'appelé par
lui »*. Un `Match` en Rust ne référence pas le catalogue : il tient des
identifiants et des valeurs simples. Le catalogue peut rester en GDScript
indéfiniment.

Sans cette phase 1, les cartes 14 et 22 auraient créé **la même chose dans deux
langages, dans le même dossier** — la divergence que toute cette architecture
existe pour interdire, à ceci près qu'elle n'aurait pas été entre deux dépôts
mais entre deux fichiers voisins.

## Les épreuves à faire échouer d'abord

- Une commande illégale est **refusée** sans muter l'état — et l'état d'après un
  refus est identique à celui d'avant, octet pour octet.
- En attente de décision, `legal_commands()` ne rend **que** les réponses
  attendues, et aucune commande ordinaire.
- L'état se sérialise et se relit en pleine attente, et le match reprend au même
  point.

## Terminé quand

- [x] `Command`, `Event`, `Match::submit()`, `legal_commands()` existent ;
- [x] l'état d'attente est représenté explicitement, pas déduit — et il **nomme
  son entraîneur**, qui n'est pas toujours l'actif ;
- [x] `EndTurn` traverse toute la chaîne ;
- [x] `fork_for_rollout` refait les dés au lieu de les copier, et c'est prouvé ;
- [x] la carte 22 est mise à jour ;
- [x] `make test-behaviour`, `make check-arch`, `make check-integrity`,
  `make check-mutations` passent.

**La sérialisation est reportée** à la carte du journal, décidée au gué de la
phase 3 — voir plus bas.


---

# Ce que la carte a appris

## La phase 1 a évité une collision que personne ne cherchait

Les cartes 14 et 22 voulaient créer **la même chose** — l'état de match — dans
deux langages, dans le même dossier. Rien ne le signalait : les deux cartes
étaient cohérentes prises séparément, et personne ne les lisait ensemble.

C'est la phase 1 du workflow qui l'a fait apparaître, en exigeant de rappeler
« ce que le noyau contient déjà » et « les cartes amont qui contraignent ».
Sans elle, on aurait écrit un `Match` en Rust pendant que la carte 22 déménageait
`match_state.gd` en GDScript, et on aurait découvert la divergence bien plus
tard — probablement en constatant que le jeu et l'entraînement ne suivent pas les
mêmes règles.

**Une carte peut être juste et fausse en même temps** : juste dans son périmètre,
fausse par rapport à ce que les autres font. Le rappel des cartes amont n'est pas
une politesse.

## Trois décisions de vocabulaire, et ce qui les a dictées

**L'émetteur n'est pas dans la commande.** `submit(by, command)` plutôt que
`Command { by, … }`, parce que l'émetteur est **affirmé par le transport et non
par le message**. Le jour où une autorité serveur recevra ces commandes par le
réseau, un client pourra mentir sur ce qu'il veut faire, jamais sur qui il est ;
mettre `by` dans la commande rendrait l'usurpation représentable.

**Un refus n'est pas un événement.** `Result<Vec<Event>, Rejected>` plutôt qu'un
`Event::Rejected`. Le document est explicite : une commande est une intention, un
événement est un fait. Un refus veut dire que rien ne s'est produit ; en faire un
fait brouillerait le récit que `io/` devra animer.

**`Pending.coach` est un champ, pas un calcul.** Et c'est la phase 2 qui l'a
imposé, en cherchant les sources dans `skills_fr.json` :

- `SIDESTEP` : *« au lieu que **l'entraîneur adverse** choisisse où ce joueur est
  Repoussé, l'entraîneur de ce joueur peut choisir… »*
- `TAUNT` : *« l'entraîneur de ce joueur peut choisir de faire **Suivre le joueur
  adverse** »*

Une décision appartient à un entraîneur nommé, et **une compétence peut en
transférer la propriété**. La déduire du tour courant serait faux la moitié du
temps, et faux silencieusement. La carte 16 l'avait pressenti sur le dé de
blocage ; deux compétences le prouvent, sur deux autres décisions.

## Une contrainte enregistrée pour la carte 16, sans être implémentée

`PRO` : *« il peut tenter de relancer **un seul dé** […] dans le cadre d'un jet
de dés multiples »*. Le jour où un événement portera un jet, il devra donc
identifier **chaque dé séparément** — on ne peut pas désigner « le deuxième des
trois » si les dés sortent en bloc.

Aucun jet n'existe encore, donc rien ne l'implémente. La contrainte est écrite
dans le commentaire d'`Event` pour que la carte 16 ne la redécouvre pas à ses
frais.

## L'échafaudage, assumé et daté

`Command::Ask`, `Command::Answer` et `Question::Confirm` ne sont pas des règles :
aucune n'existe encore qui produise une question. Sans cette paire fabriquée, le
mécanisme d'attente n'aurait été exercé par rien et n'aurait existé que sur le
papier.

**Elle interroge délibérément l'adversaire.** Une implémentation qui déduirait le
propriétaire d'une décision du tour courant passerait tous les tests si la
question revenait à l'actif : l'échafaudage est conçu pour rendre cette erreur
impossible à commettre sans échouer.

La carte 16 la supprime en la remplaçant par les vraies — choix du dé, direction
de poussée, suivi, relance.

## La sérialisation, reportée et pourquoi

Elle figurait dans « Terminé quand ». Sortie au gué de la phase 3, pour trois
raisons :

- **rien ne la consomme** — ni journal, ni instantané, ni reprise n'existent, et
  la règle de couverture à 100 % punit exactement ce genre de code ;
- **elle impose une décision qui ne lui appartient pas** : sérialiser un `Dice`,
  est-ce ses 10 000 valeurs tirées, ou seulement `(graine, curseurs)` ? La
  seconde est évidemment la bonne, et elle exige que `Dice` retienne sa graine —
  ce qu'il ne fait pas. C'est le chantier de la carte du journal ;
- **la forme reste sérialisable** : rien que des données plates, aucune
  référence, aucun `Node`. Rien ne se ferme.

## Une nuance à la phase 4 du workflow

Un test est passé au vert en phase 4 : `chaque_camp_a_un_autre`. Non pas parce
qu'il ne vérifiait rien, mais parce que `Team::other()` n'était pas un `todo!()`
— c'est un `match` de deux lignes, écrit en phase 3.

La règle telle que je l'avais écrite — *« un test vert à cette phase est un test
à réécrire »* — est trop absolue. La formulation juste : **un test vert en
phase 4 est un test à examiner.** Soit il ne vérifie rien, soit le code qu'il
couvre existait déjà. Corrigé dans le workflow.

## Une carte où la phase 6 n'a rien trouvé

Contraste avec la carte 13, où elle avait renvoyé trois fois en arrière : ici les
quatre vérifications sont passées du premier coup, sans un ajustement.

La différence n'est pas la chance. Cette carte ne touche ni à l'aléatoire, ni à
une frontière avec le monde extérieur : elle ne manipule que des données plates
et des transitions déterministes. Les trois retours de la carte 13 portaient tous
sur le point de contact entre une logique et sa source d'entropie.

C'est une indication pour les cartes suivantes : **c'est aux frontières que les
vérifications trouvent quelque chose.**
