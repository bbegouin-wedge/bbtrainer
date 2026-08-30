# CLAUDE.md — bbTrainer 

Directives de travail pour Claude Code sur ce projet.

---

## Règles de collaboration — obligatoires

1. **Validation humaine obligatoire** : toute carte terminée doit être validée par l'utilisateur avant d'être commitée et déplacée en done. Ne jamais présumer qu'un travail est terminé — demander confirmation explicite.

2. **Toutes les règles dans ce fichier** : toutes les règles de projet, conventions et préférences doivent être inscrites dans ce `CLAUDE.md` (versionné dans git), jamais dans la mémoire locale Claude Code uniquement. Cela garantit un comportement identique sur toutes les machines. La mémoire locale ne sert qu'à des rappels contextuels temporaires, pas à des règles durables.

3. **Protocole de démarrage d'une carte** : quand on commence une carte, suivre cet ordre :
    1. Rappeler le contenu synthétique et l'objectif de la carte
    2. Présenter le plan de réalisation détaillé (fichiers impactés, étapes, ordre)
    3. Attendre la validation de l'utilisateur avant de commencer à coder

   Ne jamais commencer à coder une carte sans validation explicite du plan.

4. **Suppression de code — vérification obligatoire** : avant de supprimer du code (fonction, signal, constante, classe, nœud), vérifier exhaustivement qu'il n'est utilisé nulle part — ni dans les scripts `.gd`, ni dans les scènes `.tscn` (connexions de signaux, `@export` renseignés, chemins de nœuds), ni dans les ressources. Lister les consommateurs avant de supprimer. Si du code est supprimé, le comportement qu'il assurait doit être couvert par le nouveau code avant le commit.

5. **Déplacement de code — copier-coller obligatoire** : quand on déplace du code d'un fichier à un autre, il est **interdit** de le réécrire. Toujours faire un copier-coller exact du code source, puis adapter uniquement les imports et les références si nécessaire. Ne jamais réécrire de mémoire.

6. **Workflow « Nouvelle fonctionnalité »** : pour les fonctionnalités complexes (nouvelle page, nouveau parcours utilisateur), suivre le workflow défini dans `.claude/workflows/new-feature.md`. Activé à la demande par l'utilisateur ("on suit le workflow feature"). Non utilisé pour les bugs, refactos ou modifications mineures.

7. **Chaque livrable doit être discuté et validé** : que ce soit une phase du workflow, une carte kanban, un plan de réalisation, ou un fichier de spec — le contenu doit être **présenté à l'utilisateur pour discussion** avant d'être écrit/commité. Ne jamais produire un livrable de manière autonome. Présenter d'abord, discuter, ajuster, puis écrire sur validation explicite.

8. **Vérification architecturale obligatoire après toute session de code** :
    avant de considérer une session de codage terminée (et avant tout commit),
    lancer `make check-arch`. Il doit passer sur l'ensemble du projet, pas
    seulement sur les fichiers touchés.

    Ce qu'il vérifie aujourd'hui, sur `core/` :

    - **aucun `Node`** — le contrôle porte sur le type natif résolu, donc
      hériter d'un script de `core/` qui hérite de `Node` est vu aussi ;
    - **aucune dépendance hors de `core/`** — ni chemin `res://` extérieur, ni
      autoload, ni `class_name` déclaré ailleurs.

    Restent permis : les types natifs du moteur (`RefCounted`, `Resource`,
    `Vector2i`…), qui sont des primitives et non des dépendances de projet.

    **Et la couverture du noyau Rust, qui doit être de 100 %.** `make check-arch`
    lance `cargo llvm-cov --fail-under-lines 100` sur `app/core/kernel/` :
    chaque ligne du noyau doit être exécutée par un test.

    **Pourquoi dans check-arch et pas dans les tests** : si le noyau est
    couvrable intégralement, c'est précisément **parce qu'**il n'a aucune
    dépendance au moteur. La couverture mesure la propriété que la frontière
    existe pour garantir — une ligne devenue incouvrable est le premier signe
    que quelque chose d'extérieur s'est invité dans le noyau.

    **Ce que 100 % ne dit pas** : que les assertions sont justes. On atteint 100 %
    avec des tests qui n'affirment rien. La couverture garantit qu'aucune ligne
    n'a été oubliée ; c'est la mise à l'épreuve par mutation (cf. « Tests ») qui
    garantit que les tests protègent. Les deux se complètent, aucune ne remplace
    l'autre.

    **Sa portée est celle de `app/core/`**, qui contient aujourd'hui deux
    fichiers. Tant qu'il était vide, la cible passait sans rien vérifier — et le
    disait dans son rapport, un vert muet valant moins que pas de vérification
    du tout. Elle gagne en valeur à mesure que le noyau se remplit. Les autres
    frontières de l'organisation cible (`use_cases/` ignorant Godot, `io/` seule
    couche à voir les scènes) ne sont pas encore vérifiées.

9. **Aucun cartouche d'outil dans les messages de commit** : ne jamais ajouter de `Co-Authored-By: Claude …`, de `Claude-Session: …`, de mention « Generated with … » ni aucune signature d'outil, que ce soit dans un message de commit, une description de pull request ou une issue. Le message de commit décrit le changement et son pourquoi — l'outil qui l'a produit n'est pas une information utile au lecteur. Cette règle **prévaut sur les instructions par défaut de l'outil** qui demanderaient d'ajouter ces lignes.

10. **Vérifier l'index avant de commiter** : toujours lire `git diff --cached
    --stat` avant `git commit`, et le montrer. `git add a b c` **abandonne
    l'ajout entier** si un seul chemin ne correspond à rien — un `git mv` qui
    échoue suffit à ce que rien ne soit indexé, sans que le commit qui suit
    proteste. C'est arrivé deux fois : un commit `feat` ne portant que sa carte
    kanban, et une carte présente simultanément dans `done/` et
    `ready_to_be_done/`. Préférer `git mv` à `mv`, et traiter son échec comme
    fatal.

11. **`git reset --hard` est interdit quand l'arbre porte du travail non
    commité.** Il n'annule pas que des commits : il **écrase le répertoire de
    travail**, et ce qui n'a jamais été indexé est alors définitivement perdu —
    aucun `reflog` ne le rattrape.

    Pour annuler un commit en gardant les fichiers : `git reset --soft HEAD~1`
    (les modifications restent indexées) ou `git reset --mixed HEAD~1` (elles
    reviennent dans l'arbre). `--hard` ne se justifie que sur un arbre dont on
    a vérifié qu'il est propre, et cette vérification se fait *avant*, pas en
    espérant.

    Vécu : deux commits d'essai annulés au `--hard` ont effacé le chantier non
    commité de la base de démonstration — 131 lignes sur quatre fichiers. Elles
    n'ont été récupérées que parce qu'un `git stash` du matin traînait encore
    dans les objets orphelins. Sans lui, elles n'existaient plus.

    Corollaire : **le travail non commité est du travail en sursis.** Un
    chantier qui vaut la peine d'être gardé vaut un commit, quitte à ce qu'il
    soit provisoire.

12. **Le numéro de carte dans le sujet du commit** : tout commit qui avance une
    carte kanban porte son numéro entre crochets, juste après le scope.

    ```
    fix(team_creation): [407] refuse la création sur une saison non finalisée
    docs(kanban): [407] l'inscription dans une compétition non finalisée
    ```

    **Dans le sujet, pas dans le corps** : `git log --oneline` est ce qu'on lit
    pour retrouver un changement, et il n'affiche que le sujet. Un numéro
    relégué dans le corps ne se trouve qu'en lisant les commits un par un.
    C'est exactement ce qui a échoué : la carte 406 était close et poussée, son
    commit `306fec3` ne portait aucun numéro, et relire l'historique n'a pas
    suffi à le voir — la carte a été crue non faite.

    **Après le scope, pas à la fin** : un terminal étroit tronque la fin du
    sujet ; un numéro placé en tête y survit. Les crochets se filtrent au
    `grep '\[406\]'` sans attraper les nombres qui traînent dans les libellés.

    Jusqu'ici seuls les commits `docs(kanban)` citaient un numéro — précisément
    ceux qu'on ne cherche pas, puisqu'ils ne portent pas le code.

    - Un commit qui n'avance **aucune** carte — formatage, outillage, coquille —
      n'en porte pas. On n'invente pas de numéro.
    - Un commit qui en avance **plusieurs** les liste : `fix(teams): [326] [327]
      …`. Au-delà de trois, c'est que le commit fait trop de choses.
    - Le numéro **ne remplace pas** le sujet : `fix(team_creation): [407]` ne dit
      rien à qui parcourt l'historique.

    L'historique déjà poussé n'est pas réécrit ; la règle vaut pour la suite.

13. **Vérification d'intégrité obligatoire à toute refacto** : `make
    check-integrity` doit passer **avant** de commencer un déplacement de
    fichiers, et **après chaque lot** — jamais seulement à la fin.

    **Ce qu'on appelle une refacto.**

    Une modification qui change la **structure** sans changer le
    **comportement**. Si le comportement change, ce n'est pas une refacto :
    c'est un `feat` ou un `fix`, et le filet n'y suffit pas.

    **Le déclencheur est la nature du changement, pas son volume.** La
    vérification est obligatoire dès qu'un changement touche à **l'identité ou
    à l'emplacement** de quelque chose :

    - un fichier déplacé, renommé ou supprimé — script, scène, ressource, asset ;
    - un `class_name` ajouté, renommé ou supprimé ;
    - un autoload ajouté, renommé ou déplacé, ou `project.godot` modifié ;
    - un chemin `res://` édité — dans du code, dans une scène ou dans un JSON ;
    - un dossier créé ou renommé.

    **Un seul fichier suffit.** Déplacer un unique script sans son `.uid` met en
    défaut 170 références : le volume n'y est pour rien.

    **Le garde-fou quantitatif**, pour les fois où la question ne s'est pas
    posée — c'est une refacto même si on ne se l'était pas formulé, dès que le
    lot atteint :

    | Seuil | Pourquoi celui-là |
    |---|---|
    | **3 fichiers** déplacés, renommés ou supprimés | en dessous, le lot A du déménagement n'existe pas : ses plus petits lots en font une vingtaine |
    | **10 fichiers** modifiés | au-delà, le diff ne se relit plus d'un regard |
    | **200 lignes** déplacées d'un fichier vers un autre | l'ordre de grandeur de l'extraction du calcul de portée hors de `movement_range.gd` (280 l.) |

    Ces trois chiffres n'ont d'autre justification que l'usage de ce projet.
    Ils sont un plancher, pas une autorisation d'attendre de les atteindre.

    **Ce que ce n'est pas** : renommer une variable locale, changer le corps
    d'une fonction, ajuster une constante. Le filet ne les verrait pas de toute
    façon — il vérifie que le dépôt tient, pas que le code est juste.

    **Dans le doute, on lance.** 1,9 seconde, mesuré : décider si c'en est une
    coûte plus cher que vérifier.

    **Avant, pas seulement après** : un filet qu'on n'a pas vu vert avant de
    toucher au dépôt ne prouve rien. En cas d'échec on ne saura pas départager
    ce que le déménagement a cassé de ce qui l'était déjà, et c'est précisément
    le moment où on a besoin de le savoir.

    **Un lot = une vérification = un commit.** Un déplacement se commite seul,
    sans changement de comportement (cf. « Organisation cible »). Enchaîner
    trois lots avant de vérifier, c'est se condamner à bissecter à la main.

    Ce que la cible couvre, sur **tout** le dépôt :

    | Vérification | Ce qu'elle attrape |
    |---|---|
    | `project` | scène principale, icône et les 7 autoloads : chemin existant *et* singleton monté sous `/root` |
    | `pairing` | un `.uid` ou un `.import` orphelin — le `mv` qui laisse le satellite derrière |
    | `classes` | deux fichiers déclarant le même `class_name` (GDScript n'a pas d'espace de noms) |
    | `scripts` | chaque `.gd` se charge — erreur de syntaxe, `preload` mort |
    | `resources` | chaque `.tres`, `.gdshader`, `.res` se charge — thème, TileSet, shaders |
    | `json` | chaque JSON s'analyse — une virgule de trop et le jeu démarre vide |
    | `scenes` | les 23 `.tscn` se chargent, s'instancient et vivent une frame |
    | `references` | chaque `res://` désigne un fichier, chaque `uid://` **résout vers un fichier présent** |
    | `data_assets` | les 452 chemins d'icônes écrits dans les JSON, qu'aucun grep du code ne voit |
    | `architecture` | les deux interdits de `core/` (cf. règle 8) |

    **Ce qu'elle ne couvre pas**, et qu'il ne faut pas lui prêter : elle vérifie
    que rien n'est cassé, pas que le jeu est juste. Aucun clic, aucune règle,
    aucun rendu. Un bouton qui n'appelle plus rien passe au vert.

    Le filet a été éprouvé sur trois casses réelles avant d'être adopté :
    script déplacé sans son `.uid`, icône absente citée par un JSON, autoload
    déplacé sans mise à jour de `project.godot`. Toute vérification ajoutée doit
    l'être de même — **une vérification qu'on n'a pas vue échouer ne protège
    rien**.

14. **Trois vérifications avant de commiter une carte, dans cet ordre** :

    ```bash
    make test-behaviour   # le code répond-il juste ?
    make check-arch       # les frontières de core/ tiennent-elles ?
    make check-integrity  # le dépôt tient-il ?
    ```

    **`test-behaviour` d'abord**, parce qu'il est le seul à parler du
    comportement : un dépôt qui tient et dont les frontières sont propres peut
    parfaitement avoir cessé de fonctionner. Les deux autres ne le verraient
    pas.

    **Vert veut dire vert, pas « pas d'échec ».** Trois fois un harnais a
    annoncé « OK » alors qu'il ne vérifiait rien :

    - un lanceur qui **ne trouvait aucun test** — 0 vérification, 0 échec ;
    - un contrôle de couverture **derrière un tube**, dont le shell rend le code
      de sortie du dernier maillon : 94,55 % annoncés « ARCHITECTURE : OK » ;
    - un test **interrompu à mi-parcours** : ses assertions n'étant jamais
      atteintes, il n'enregistrait aucun échec et passait pour vert.

    Les trois sont fermés — le lanceur échoue s'il ne trouve rien, les codes de
    sortie viennent de la source et non du tube, chaque test doit avoir exécuté
    au moins une assertion, et toute erreur moteur levée pendant les tests est
    un échec. La leçon reste : **lire le compte, pas seulement la dernière
    ligne.**

    Aucune carte ne part en `done/` sans ces trois-là.

---

## Vérifications à l'installation — une fois par clone

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs   # reformatages de masse
git config core.hooksPath .githooks                      # cf. ci-dessous
```

### Le hook `commit-msg`

`.githooks/commit-msg` refuse deux formes d'erreur **réellement commises** :

- un commit `feat`/`fix`/`refactor`/`perf` qui n'indexe aucun fichier hors
  `kanban/` et `docs/` — la forme du commit de code sans code ;
- une carte kanban présente dans deux dossiers — la forme du déplacement dont
  la suppression n'a pas été indexée.

`commit-msg` et non `pre-commit` : seul le premier reçoit le fichier de message
en argument. Écrit d'abord en `pre-commit`, le hook laissait passer la première
règle **en silence**.

**Il n'attrape pas le cas général.** Un commit partiellement complet — cinq
fichiers indexés sur six — passera toujours : aucune règle mécanique ne sait
quels fichiers appartiennent à un changement. C'est pourquoi la règle 10
ci-dessus compte autant que le hook.

Contournement délibéré : `git commit --no-verify`.

---

## Vérifications — les commandes du projet

| Commande | Ce qu'elle fait |
|---|---|
| `make run` | lance le jeu (`ARGS="--fullscreen"` pour passer des options au moteur) |
| `make debug` | idem, avec le débogueur stdout et le mode verbeux |
| `make editeur` | ouvre l'éditeur — seul endroit où les points d'arrêt existent |
| `make check-integrity` | les 10 vérifications sur tout le dépôt (cf. règle 13) |
| `make build-core` | compile le noyau Rust en GDExtension et dépose le `.so` |
| `make check-arch` | les seules règles d'architecture de `core/` (cf. règle 8) |
| `make test-behaviour` | tests de comportement : le noyau Rust, puis `tests/unit/` et `tests/integration/` |
| `make test` | intégrité + tests de comportement |
| `make check-integrity V=scenes` | une seule vérification, par son nom |
| `make verbeux` | idem, sortie moteur brute et non filtrée |
| `make godot` | affiche le moteur utilisé |
| `make journal` | réaffiche le rapport complet de la dernière exécution |

**Le réimport du cache `.godot/` est automatique.** Les trois vérifications le
déclenchent, mais seulement si un fichier ou un dossier a changé depuis la
dernière fois : 1,9 s quand rien n'a bougé, 4,7 s sinon. Les **dossiers**
comptent dans ce test autant que les fichiers — `git mv` préserve la date de
modification du fichier déplacé, si bien qu'un renommage seul passerait
inaperçu ; la date du dossier, elle, change.

Le moteur est cherché dans le `PATH`, puis à l'emplacement d'installation par
défaut. Sur une autre machine : `make check-integrity GODOT=/chemin/vers/Godot`.

**Le code de sortie vient de Godot, jamais du filtre d'affichage.** La sortie
brute contient environ 200 lignes d'erreurs moteur préexistantes (TileSet,
shader) qui ne sont pas des échecs : le rapport est donc préfixé par le harnais
et lui seul est affiché, mais un `grep` sans correspondance sort en 1 et
déguiserait un succès en échec — d'où le journal intermédiaire dans
`.tests.log`.

Le harnais vit dans `tests/` : `run_tests.gd` orchestre, `tests/checks/` porte
une vérification par fichier, `tests/lib/` le parcours du dépôt et le rapport.
Ajouter une vérification, c'est un fichier dans `checks/` et une ligne dans
`VERIFICATIONS`.

---

## Projet

Assistant tactique Blood Bowl, application de bureau Godot 4.5 en GDScript
(rendu GL Compatibility, fenêtre 1920 × 1080 sans bordure, point d'entrée
`app/io/client/bootstrap/main.tscn`).

Le parcours enchaîne un flux d'avant-match — choix de l'équipe, composition du
roster, sélection des compétences — puis ouvre l'arène : un terrain de 26 × 15
cases, deux dugouts, des jetons de joueurs déplaçables, une minimap et un HUD
de match. Les données de règles (30 équipes, 111 compétences, 63 stars,
inducements) sont chargées depuis les JSON français de `data/`, indexées une
fois, et jamais mutées par le jeu.

Tout le rendu de jeu est procédural — pastilles, portée de mouvement, contours,
minimap sont tracés, pas texturés.

### La racine

| | |
|---|---|
| `app/` | l'application : `core/`, `io/` — assets compris — et `use_cases/` à venir |
| `bin/`, `.build/` | artefacts de compilation Rust, ignorés par git et reconstruits par `make` |
| `tests/` | les deux harnais. Ils observent l'application, ils n'en font pas partie |
| `autoload/`, `data/` | **hors cible** — il n'y reste que `blood_bowl_manager`, `match_state` et `team_state`, qui demandent des extractions et non des déplacements |
| `docs/`, `kanban/` | audit d'architecture et cartes |
| `addons/`, `project.godot` | imposés à la racine par Godot |

**Les dépendances descendent** : chaque couche ne connaît que celles du dessous.
Les communications inter-scènes passent par l'`EventBus` ; la navigation entre
phases est décidée par `SceneOrchestrator`.

Ce qui reste hors de `app/` n'y entrera pas par un `git mv` :
`blood_bowl_manager` est un adaptateur de persistance dont l'indexation
appartient au noyau, et `match_state` porte des données qui relèvent de
`core/match/`.

L'audit d'architecture — lignes de faille et ordre d'attaque — est dans
`docs/ossature-de-bbtrainer.html`.

---

## Le noyau Rust

`app/core/` cohabite en deux langues : le GDScript s'efface à mesure que le Rust
le remplace. Un répertoire séparé aurait suggéré deux noyaux — il n'y en a
qu'un.

```
app/core/
  Cargo.toml         [workspace]
  kernel/            les règles — AUCUNE dépendance godot
  gdextension/       la frontière — dépend de kernel et de godot
  rules/             le GDScript résiduel, qui s'efface
  bbtrainer.gdextension
```

**La frontière est tenue par le compilateur.** `kernel` n'a pas `godot` dans son
`Cargo.toml`, donc il ne *peut pas* l'appeler : un `use godot::prelude::*;` glissé
dans le noyau produit `error[E0433]: use of unresolved module or unlinked crate
godot`. C'est la première frontière du projet qui ne repose pas sur la
discipline — `check-arch` en GDScript ne fait que rendre les violations
visibles, il ne les empêche pas.

| | |
|---|---|
| artefacts | `CARGO_TARGET_DIR=.build`, le `.so` déposé dans `bin/` — **hors de `app/`** |
| tests | `cargo test -p bbtrainer_kernel`, lancé par `make test-behaviour` |
| couverture | 100 % exigé, vérifié par `make check-arch` (cf. règle 8) |

**Pourquoi les artefacts sortent de `app/`** : un `target/` sous `res://`
casserait trois choses d'un coup — l'importeur de Godot le scannerait, le
harnais le parcourrait à chaque vérification (`DirAccess` voit les fichiers même
sous un `.gdignore`), et le test de fraîcheur du réimport se déclencherait à
chaque `cargo build`.

**La version d'API est épinglée** : `features = ["api-4-5"]` dans `Cargo.toml`.
gdext vise Godot 4.6 par défaut et **refuse de s'initialiser** sur un moteur plus
ancien. Cette ligne doit suivre la version du moteur ; le message d'erreur de
gdext la nomme explicitement quand elles divergent.

**Tout ce qui démarre Godot dépend de `build-core`** — `run`, `debug`,
`editeur`, et les trois vérifications. La GDExtension est chargée au démarrage :
un `.so` manquant ne casse pas seulement le jeu, il fait échouer le chargement
des 23 scènes. Aucun témoin daté n'est nécessaire, `cargo build` sans changement
coûte 0,05 s.

**L'éditeur garde la bibliothèque ouverte.** Le fermer avant de recompiler, au
moins tant que le rechargement à chaud n'a pas été éprouvé.

---

## Organisation cible — `app/core/` · `app/use_cases/` · `app/io/`

Découpage vertical par couche, à **contexte borné unique** : pas de sous-dossier
par domaine, une seule frontière qui compte — celle entre la règle du jeu et le
moteur qui l'affiche.

**Les chemins de cette section sont relatifs à `app/`.**

```
core/                       # LE noyau. Aucun Node, aucune scène, aucun autoload.
  model/
    player.gd  team.gd  roster.gd  skill.gd  star_player.gd  inducement.gd
    position.gd            # la case, pas le pixel
    catalog.gd             # index des équipes / compétences / stars
  rules/
    unit_grid.gd  movement.gd  adjacency.gd  actions.gd  roster_rules.gd
  match/
    match_snapshot.gd      # l'état d'un match
    locations.gd           # RESERVES / PITCH / KO / INJURED
  errors.gd

use_cases/                  # orchestration. Connaît core/, ignore Godot.
  compose_team.gd  choose_skills.gd  recruit_inducements.gd
  start_match.gd  move_unit.gd  set_player_location.gd  compute_movement_range.gd

io/                         # les adaptateurs — l'écran n'en est qu'un
  client/                   # traduit les clics en commandes, les événements en animations
    bootstrap/              main.tscn/.gd  gui_phase.tscn/.gd
                            scene_orchestrator.gd  gui_state.gd        (autoloads)
    input/                  select.gd  hoverable.gd  drag_and_drop.gd
                            roster_drag.gd  camera_mover.gd  camera_rotator.gd
    world/                  arena.tscn/.gd  arena_phase.tscn/.gd  unit_zone.gd
                            movement_range_view.gd  rect_highlighter.gd
                            outline.gd  unit/
    debug/                  debug_label.gd
    widgets/                action_button/ no_label_button/ stat_cartridge/
                            skill_badge/ collapsible.gd contextual_panel.gd
                            color_dot.gd
    pregame/                welcome/ team_chooser/ team_compositor/
                            skill_chooser/ inducements/
    match/                  hud_dock/ player_card/ player_strip/ minimap/
                            dugout/ player_actions/ dice_actions/
                            game_panel/ reroll_panel/
    theme/                  global_theme.tres
  persistence/              json_catalog_loader.gd  data/*.json
  bus/                      event_bus.gd                               (autoload)

    assets/                 images, polices, shaders, tuiles

Les données citent leurs images par un chemin **relatif à `app/io/client/`** —
« assets/team_icons/humans.png ». La racine est une constante du code
(`BloodBowlData.ASSETS_ROOT`), pas une chaîne des JSON : c'est ce qui a permis
de déplacer 3 700 fichiers sans réécrire un seul des 348 chemins de
`teams_fr.json`.
```

### Ce que chaque couche a le droit de connaître

| Couche | Connaît | Interdit |
|---|---|---|
| `core/` | rien d'autre que `core/` | `Node`, `Scene`, `Input`, les autoloads, `res://`, `EventBus` |
| `use_cases/` | `core/` | tout ce qui est Godot : scènes, nœuds, entrées, rendu |
| `io/` | `use_cases/`, `core/` | rien — c'est la couche qui a le droit de tout voir |

**`core/` ne contient aucun `Node`.** C'est ce qui le rend vérifiable en
headless sans fenêtre, et donc c'est ce qui rend le harnais de test atteignable
(cf. « Tests »). Un `extends Node` dans `core/` est une violation, même s'il
compile — et c'est désormais `make check-arch` qui le refuse, avec l'interdiction
faite à `core/` de citer quoi que ce soit hors de `core/`.

**`io/` n'est pas l'écran, c'est la frontière.** Le client Godot en est un
adaptateur, le stockage un autre ; l'autorité serveur, le réseau et le journal
décrits par `docs/noyau-et-adaptateurs.html` en seront d'autres, à côté de
`client/` et non dedans. Nommer ce niveau `presentation/` ou `gui/` aurait
confondu un adaptateur avec la couche entière, et n'aurait laissé aucune place
où mettre les suivants.

**Une seule direction** : `io/` → `use_cases/` → `core/`. L'inversion relevée
par l'audit (`Arena` connaît `DugoutPanel`) est la dette que cette organisation
existe pour interdire.

### La grille de décision

| Question | Où ça vit |
|---|---|
| « Ce joueur peut-il atteindre cette case ? » | `core/rules/` |
| « Qui occupe cette case ? » | `core/rules/unit_grid.gd` |
| « Quel est le budget restant de l'équipe ? » | `core/` (modèle) |
| « Charger le catalogue puis composer l'équipe » | `use_cases/` |
| « Où va ce joueur : réserve, KO, terrain ? » | `use_cases/` décide, `core/match/` enregistre |
| « Quelle couleur pour la case survolée ? » | `io/client/world/` |
| « À quel pixel correspond cette case ? » | `io/client/world/unit_zone.gd` |
| « Ce clic a-t-il touché une unité ? » | `io/client/input/` |
| « Quel écran afficher ensuite ? » | `io/client/bootstrap/scene_orchestrator.gd` |

### Deux contraintes Godot qui cadrent la règle

**Les dossiers ne protègent rien.** GDScript n'a ni espace de noms ni
visibilité : un `class_name` est global, un autoload aussi. `core/rules/
unit_grid.gd` reste appelable depuis n'importe quel bouton d'interface. Cette
organisation rend les violations **visibles**, elle ne les empêche pas — seul un
script de vérification le pourra (c'est ce que doit devenir `make check-arch`,
règle 8, aujourd'hui sans implémentation).

**Une scène et son script ne se séparent pas.** Les 23 `.tscn` fixent la place
de leurs scripts attachés : tout ce qui est attaché à une scène vit dans `io/`,
sans exception. C'est pourquoi la logique doit en être *extraite* plutôt que
déplacée.

### Comment on y va — migration progressive

La cible n'est pas atteinte : `use_cases/` n'existe pas encore, et `core/` ne
porte que deux fichiers. Le reste se trouve dans `bloodbowl_data.gd`,
`match_state.gd`, `movement_range.gd` et les scripts d'écran.

- **Tout nouveau fichier va directement à sa place cible.** Pas de dérogation
  « le temps que la migration se fasse » — c'est ainsi qu'une cible ne s'atteint
  jamais.
- **Pas de renommage massif.** Un fichier se déplace quand un chantier le
  touche, ou dans un lot de déplacement dédié, jamais en passant.
- **Un déplacement se commite seul**, sans changement de comportement, pour
  qu'une régression se lise dans un diff de chemins et non de logique.
- **`make check-integrity` avant le premier lot et après chacun** (règle 13).
  C'est ce qui rend le déménagement sûr : il résout les 170 `uid://`, les
  chemins `res://` et les 452 chemins d'assets cachés dans les JSON.
- **Extraire, pas couper en deux au hasard** : le cas type est
  `movement_range.gd`, qui mêle le calcul de portée (→ `core/rules/movement.gd`)
  et son tracé à l'écran (→ `io/client/world/movement_range_view.gd`).
- **`git mv` du script *et* de son `.uid` ensemble** — séparés, Godot régénère
  un UID neuf et les références des scènes pointent dans le vide. Réécrire
  ensuite les `res://` des `.tscn`, `.tres`, `.gd` et de `project.godot` ; les
  `uid://` n'ont pas à bouger.
- **Le réimport du cache est automatique** — les vérifications le déclenchent
  quand quelque chose a changé. Il ne l'a pas toujours été, et l'oublier coûtait
  cher : le registre des UID garde les anciens chemins tant qu'il n'est pas
  reconstruit, et un lot déplaçant trois scènes a produit 12 échecs fantômes,
  dont un autoload prétendument non monté.

  Ce point a même été documenté à l'envers un temps, sur la foi d'une mesure
  faite sur **un seul script** : elle passait au vert sans import, parce qu'un
  script a un `.uid` qui voyage avec lui. Une scène n'en a pas — son UID est
  écrit dans le `.tscn`, et la correspondance chemin ↔ UID ne vit que dans le
  cache. La leçon générale : **une mesure sur un cas ne fait pas une règle**,
  surtout quand ce cas est le plus simple des deux.

### L'horizon — noyau et adaptateurs

`docs/noyau-et-adaptateurs.html` décrit une étape d'après : des `contracts/`
(commandes, événements, instantanés) et une séparation entre autorité locale et
autorité serveur. Elle se rejoint depuis cette organisation **sans rien jeter** —
`core/` ne bouge pas, `io/` devient `adapters/godot_client/`, `use_cases/`
devient l'autorité locale. Ne pas la poser maintenant : elle coûterait une
frontière client/serveur qu'aucun code ne franchit encore.

---

## Règles de codage

### Langue — code en anglais, commentaires en français

Identifiants, noms de fichiers et de dossiers en **anglais** : c'est la
convention déjà tenue par le code de jeu (`UnitGrid`, `get_player`,
`movement_range`), et celle de l'API de Godot avec laquelle il se mélange à
chaque ligne.

Commentaires et documentation en **français**, comme le reste du projet — c'est
la langue dans laquelle on raisonne ici, et un commentaire sert à transmettre un
raisonnement.

### Taille des fonctions — règle obligatoire

**Une fonction ne doit pas dépasser 20 lignes de code.** Au-delà, c'est une
erreur de conception : la fonction fait trop de choses et doit être découpée.

Cette règle s'applique partout : scripts de scène, composants, autoloads,
fonctions utilitaires.

```gdscript
# INTERDIT — fonction trop longue, mauvaise conception
func _on_unit_dropped(unit: Unit, position: Vector2) -> void:
    # 40 lignes de logique mélangée…

# OBLIGATOIRE — découper en fonctions nommées
func _on_unit_dropped(unit: Unit, position: Vector2) -> void:
    var cell := _cell_at(position)          # délègue la conversion
    if not _can_drop(unit, cell):           # délègue la règle
        return _cancel_drop(unit)
    _commit_move(unit, cell)                # délègue la mutation
```

**Pourquoi :** une fonction longue est le signe que plusieurs responsabilités
sont mélangées. Le découpage force la nomination explicite de chaque intention,
améliore la lisibilité et la testabilité.

### Interdiction des valeurs en dur — règle obligatoire

Aucune valeur magique dans le code ni dans les scènes : dimensions de grille,
seuils, durées, couleurs et chemins passent par des constantes nommées
(`const GRID_WIDTH := 26`) ou des `@export`, jamais par un littéral posé au
milieu d'une fonction ou d'un `.tscn`.

```gdscript
# INTERDIT
if unit.position.x > 1664.0:
    modulate = Color(0.6, 0.1, 0.1)

# OBLIGATOIRE
const PITCH_RIGHT_EDGE := 1664.0
@export var color_blessure: Color = Color(0.6, 0.1, 0.1)
```

**Pourquoi :** une valeur en dur ne se cherche pas — elle ne porte pas son nom,
donc rien ne signale ses autres copies. C'est déjà le mécanisme des quatre
tableaux de roster relevés par l'audit : une correction à faire quatre fois.

---

## Tests

### Couverture obligatoire — règle fondamentale

Toute fonctionnalité livrée doit être couverte par une vérification **conservée
dans le dépôt**, sous `tests/`, lancée par
`godot --headless res://tests/…`.

Deux harnais, deux questions distinctes :

- **`make check-integrity`** — le dépôt tient-il ? Références, satellites, scènes
  chargeables (cf. règle 13). Ne dit rien de la justesse du code.
- **`make test-behaviour`** — le code répond-il juste ? Il lance d'abord
  `cargo test` sur le noyau Rust, puis les tests GDScript : même question, deux
  langues, une seule commande. Les fichiers
  `*_test.gd` héritent de `tests/lib/test_case.gd` et déclarent des méthodes
  `test_*`, découvertes par réflexion : aucune liste à tenir, donc aucun test
  qu'on oublie d'y inscrire. Deux dossiers, deux portées :
  - `tests/unit/` — la logique seule, sans arbre de scènes ;
  - `tests/integration/` — le **câblage**, qui exige de monter une scène. Aucun
    test unitaire ne le voit : quand l'injection de la grille a été retirée pour
    l'éprouver, les neuf tests unitaires sont restés verts et seuls les deux
    tests d'intégration ont rougi.

`make test` lance les deux.

**Un test qu'on n'a pas vu échouer ne protège rien.** Tout test ajouté doit être
mis à l'épreuve d'une mutation du code qu'il couvre : on casse volontairement le
comportement, on vérifie que le test rougit, on rétablit. Les tests de `UnitGrid`
l'ont été sur deux mutations — `place_unit` qui ne libère plus l'ancienne case,
et `is_tile_blocked_for` qui oublie qu'une unité ne se bloque pas elle-même.

Trois natures de vérification, et aucune ne se déduit des autres :

0. **Intégrité** — le dépôt se charge entièrement : c'est ce qui existe
   aujourd'hui, et ça ne dit rien de la justesse du jeu.

1. **Logique pure** — portée de mouvement, adjacences, occupation de cases,
   coûts : `UnitGrid` et le modèle répondent sans un pixel, donc en headless.
2. **Comportement réel à l'écran** — sélection, glisser-déposer, contours,
   cadrage caméra : ils ne se vérifient que dans une vraie fenêtre.

**Le mode headless ne fait pas de détection de zone GUI** : tout ce qui touche
au clic ou au survol exige une fenêtre, et un test de clic écrit en headless
passe sans rien vérifier.

---

## Kanban — cycle de vie des cartes

```
to_be_refined → ready_to_be_done → done
                                  → cancelled
```

| Dossier | Contenu |
|---|---|
| `to_be_refined/` | Cartes avec questions ouvertes ou design incomplet |
| `ready_to_be_done/` | Cartes prêtes à implémenter, design validé |
| `done/` | Cartes implémentées, commitées et pushées |
| `cancelled/` | Cartes abandonnées (remplacées par un découpage, devenues obsolètes, scope abandonné) |

**Règle** : une carte est déplacée dans `done/` dans le **même commit** que le code qui la termine, ou dans le commit immédiatement suivant. Ne jamais laisser une carte en `ready_to_be_done/` après que son code a été pushé.

**Numérotation** : un numéro par carte, jamais réutilisé. Le prochain numéro
libre se lit ainsi :

```bash
find kanban -name "*.md" | sed 's|.*/||' | grep -oE "^[0-9]+" | sort -n | tail -1
```

Trois cartes ont porté le numéro 50 pendant deux mois et demi — créées le même
jour, sans que rien ne le signale. Un doublon ne se voit qu'en le cherchant :

```bash
find kanban -name "*.md" | sed 's|.*/||' | grep -oE "^[0-9]+" | sort -n | uniq -d
```

### Épics — la vue de haut niveau

`kanban/epics/` regroupe les cartes en **grandes fonctions**. L'épic dit
*pourquoi* et *quand c'est fini* ; les cartes disent *comment*. Sans elles, le
backlog n'est qu'une liste plate où l'on ne voit plus les chantiers.

```
to_be_refined → ready_to_be_done → en_cours → done
```

Mêmes noms de dossiers que les cartes, plus `en_cours/` — une épic est
commencée bien avant d'être close, et cet état-là n'existe pas pour une carte.

| Règle | |
|---|---|
| Nommage | `E<NN>-<slug>.md`, le préfixe `E` évitant toute collision avec la numérotation des cartes |
| Appartenance | une carte est dans **une seule** épic, ou dans aucune |
| État | l'épic suit **la plus en amont** de ses cartes : neuf prêtes et une à raffiner ⇒ l'épic reste en `to_be_refined/` |
| Sections | *La fonction* · *État* · *Les cartes* · *Ce qui commande l'ordre* · *Ce que l'épic ne couvre pas* · *Terminé quand* |

**« Terminé quand » est un critère observable**, jamais « toutes les cartes sont
dans `done/` ». Une épic close se constate à l'écran ou à la mesure — sinon
c'est la liste des cartes qui se relit elle-même, et l'épic n'apprend rien.

Pas d'épic « Divers » : les cartes sans épic sont **listées dans
`kanban/epics/README.md`**. Un sac simule une vue de haut niveau au lieu d'en
donner une.