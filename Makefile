# Vérifications du projet — cf. CLAUDE.md.
#
# `make check-integrity` est le filet : il vérifie que rien n'est cassé dans
# TOUT le dépôt — configuration, satellites, scripts, ressources, données,
# scènes, références, assets. Il ne vérifie pas que le jeu est juste.
#
# Obligatoire avant et après toute refacto ou déplacement de fichiers.

SHELL := /bin/bash

# Chemin du moteur. Surchargeable : make check-integrity GODOT=/chemin/vers/Godot
GODOT ?= $(shell command -v godot 2>/dev/null || echo $(HOME)/Applications/godot/Godot_v4.5.1-stable_linux.x86_64)

JOURNAL := .tests.log

# Réimport conditionnel du cache .godot/ — uid_cache.bin, liste des class_name,
# assets convertis. Sans lui, un déplacement laisse le registre des UID sur les
# anciens chemins et le filet crie au loup : le lot du monde a produit 12 échecs
# fantômes qui ont tous disparu à l'import.
CARGO_TARGET := .build
LIB          := bin/libbbtrainer_gdextension.so

STAMP       := .godot/.import-stamp
IMPORT_SCAN := app autoload tests project.godot

# Vérification à lancer seule : make check-integrity V=scenes
V ?=

# Filtre de mutation : make check-mutations M=grid.rs — glob de fichier, relatif
# au crate du noyau. Sans lui, tout le noyau est muté.
M ?=

.PHONY: help run debug editeur build-core check-integrity check-arch check-mutations test-behaviour test verbeux godot import journal

help:
	@echo "Cibles :"
	@echo "  make run                  lance le jeu"
	@echo "  make build-core           compile le noyau Rust en GDExtension"
	@echo "  make debug                idem, avec le débogueur stdout et le mode verbeux"
	@echo "  make editeur              ouvre l'éditeur (seul endroit avec points d'arrêt)"
	@echo "  make check-integrity      intégrité de tout le projet (10 vérifications)"
	@echo "  make check-integrity V=x  une seule : project | pairing | classes |"
	@echo "                            scripts | resources | json | scenes |"
	@echo "                            references | data_assets | architecture"
	@echo "  make verbeux              idem, sortie moteur brute et non filtrée"
	@echo "  make check-arch           les seules règles d'architecture (core/)"
	@echo "  make check-mutations      les tests du noyau peuvent-ils échouer ?"
	@echo "  make check-mutations M=x  seulement le module x (ex: M=grid.rs)"
	@echo "  make test-behaviour       tests de comportement (unit + integration)"
	@echo "  make test                 intégrité + tests de comportement"
	@echo "  make godot                affiche le moteur utilisé"
	@echo "  make journal              réaffiche le rapport de la dernière exécution"
	@echo ""
	@echo "Moteur : $(GODOT)"

godot:
	@test -x "$(GODOT)" || { \
	  echo "Godot introuvable ou non exécutable : $(GODOT)"; \
	  echo "Indiquer le binaire : make check-integrity GODOT=/chemin/vers/Godot_v4.x_linux.x86_64"; \
	  exit 1; }
	@"$(GODOT)" --version

# Lance le jeu dans une vraie fenêtre. `make run ARGS="--fullscreen"` passe des
# options au moteur ; ARGS reste vide par défaut.
ARGS ?=

run: godot build-core
	@"$(GODOT)" --path "$(CURDIR)" $(ARGS)

# Jeu + débogueur stdout local et sortie verbeuse. Les aides visuelles se
# demandent par ARGS, elles sont trop bavardes pour être posées par défaut :
#   make debug ARGS="--debug-collisions"            les Area2D des unités
#   make debug ARGS="--debug-canvas-item-redraw"    chaque _draw() clignote
debug: godot build-core
	@"$(GODOT)" --path "$(CURDIR)" -d --verbose $(ARGS)

# L'éditeur — seul endroit où les points d'arrêt existent. Pour attacher un jeu
# lancé par `make run` à un éditeur ouvert :
#   make run ARGS="--remote-debug tcp://127.0.0.1:6007"
editeur: godot build-core
	@"$(GODOT)" --path "$(CURDIR)" -e

# Le test de fraîcheur vit dans la recette et non dans les prérequis : un nom de
# fichier contenant une espace suffirait à faire couper make au mauvais endroit.
#
# Les DOSSIERS comptent autant que les fichiers : `git mv` préserve la date de
# modification du fichier déplacé, donc un renommage seul ne rendrait pas le
# témoin périmé. La date du dossier, elle, change — et `find` les parcourt.
# La GDExtension est chargée au DÉMARRAGE de Godot : un .so manquant ne casse
# pas seulement le jeu, il fait échouer le chargement des 23 scènes. Tout ce qui
# démarre le moteur en dépend donc. cargo build sans changement coûte 0,07 s,
# aucun témoin daté n'est nécessaire.
build-core:
	@command -v cargo >/dev/null || { echo "cargo introuvable — installer la chaîne Rust"; exit 1; }
	@CARGO_TARGET_DIR=$(CARGO_TARGET) cargo build --manifest-path app/core/Cargo.toml
	@mkdir -p bin && rm -f bin/*.so && cp $(CARGO_TARGET)/debug/libbbtrainer_gdextension.so $(LIB)
	@# rm -f avant la recopie : un renommage de paquet laisserait sinon l'ancienne
	@# bibliothèque dans bin/, ignorée par git donc invisible, et trompeuse.

import: build-core
	@if [ ! -f "$(STAMP)" ] || \
	   [ -n "$$(find $(IMPORT_SCAN) -newer "$(STAMP)" -print -quit 2>/dev/null)" ]; then \
	  "$(GODOT)" --headless --path "$(CURDIR)" --import > /dev/null 2>&1; \
	  mkdir -p .godot && touch "$(STAMP)"; \
	fi

# La sortie brute du moteur contient 199 lignes d'erreurs préexistantes
# (TileSet, shader) qui ne sont pas des échecs : le rapport est donc préfixé par
# le harnais, et seul ce préfixe est affiché. Le code de sortie vient de Godot,
# jamais du grep — un grep sans correspondance sort en 1 et déguiserait un
# succès en échec.
check-integrity: godot import
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_tests.gd -- $(V) \
	  > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^\[(ok|KO|note|----|####)\]" "$(JOURNAL)" || true; \
	grep -E "SCRIPT ERROR" "$(JOURNAL)" || true; \
	if [ $$code -ne 0 ]; then \
	  echo "INTÉGRITÉ : ÉCHEC — sortie complète du moteur dans $(JOURNAL)"; \
	else \
	  echo "INTÉGRITÉ : OK"; \
	fi; \
	exit $$code

# Règle 8 de CLAUDE.md. Sous-ensemble de check-integrity, qui l'exécute aussi.
# Recette propre plutôt qu'un appel à check-integrity : ce dernier concluait
# « INTÉGRITÉ : OK » sur un make check-arch, ce qui répond à une autre question.
# La couverture du noyau fait partie des règles d'architecture, et non des tests :
# si le noyau est couvrable à 100 %, c'est précisément PARCE QU'il n'a aucune
# dépendance au moteur. La couverture mesure la propriété que la frontière existe
# pour garantir. Elle ne dit rien de la justesse des assertions — c'est le rôle
# des mutations (cf. CLAUDE.md).
check-arch: godot import
	@CARGO_TARGET_DIR=$(CARGO_TARGET) cargo llvm-cov --manifest-path app/core/Cargo.toml \
	  -p bbtrainer_kernel --summary-only --fail-under-lines 100 > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^TOTAL" "$(JOURNAL)" | sed 's/^/[couv] /' || true; \
	if [ $$code -ne 0 ]; then \
	  echo "COUVERTURE DU NOYAU : ÉCHEC — chaque ligne du noyau doit être couverte"; \
	  grep -E "^error" "$(JOURNAL)" | head -2; \
	  exit $$code; \
	fi
	@# Le code de sortie vient de cargo, jamais du tube : avec un pipe, le shell
	@# rend celui du DERNIER maillon. La première version de cette recette
	@# annonçait « ARCHITECTURE : OK » sur une couverture de 94,55 %.
	@# Déterminisme : la même empreinte doit sortir de DEUX PROCESSUS distincts.
	@# Deux appels dans le même processus ne prouveraient rien — HashMap ne sème
	@# son hachage qu'une fois par processus, et donnerait deux fois le même
	@# ordre sur un noyau pourtant non déterministe.
	@a=$$(CARGO_TARGET_DIR=$(CARGO_TARGET) cargo test --manifest-path app/core/Cargo.toml \
	      -p bbtrainer_kernel --test empreinte -- --nocapture 2>/dev/null | grep "^EMPREINTE="); \
	b=$$(CARGO_TARGET_DIR=$(CARGO_TARGET) cargo test --manifest-path app/core/Cargo.toml \
	      -p bbtrainer_kernel --test empreinte -- --nocapture 2>/dev/null | grep "^EMPREINTE="); \
	if [ -z "$$a" ]; then \
	  echo "DÉTERMINISME : ÉCHEC — aucune empreinte produite, la vérification n'a rien vérifié"; \
	  exit 1; \
	fi; \
	if [ "$$a" != "$$b" ]; then \
	  echo "DÉTERMINISME : ÉCHEC — deux exécutions du même scénario divergent"; \
	  exit 1; \
	fi; \
	echo "[det]  empreinte identique sur deux processus"
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_tests.gd -- architecture \
	  > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^\[(ok|KO|note|----|####)\]" "$(JOURNAL)" || true; \
	if [ $$code -ne 0 ]; then \
	  echo "ARCHITECTURE : ÉCHEC — sortie complète dans $(JOURNAL)"; \
	else \
	  echo "ARCHITECTURE : OK"; \
	fi; \
	exit $$code

# La seule vérification qui interroge les TESTS et non le code : peuvent-ils
# échouer ? Elle casse le noyau une mutation à la fois et regarde si un test
# rougit. Une mutation qui survit est un test manquant — le code fait quelque
# chose que rien ne vérifie. C'est la version mécanique de « un test qu'on n'a
# pas vu échouer ne protège rien » (CLAUDE.md, « Tests »).
#
# À lancer APRÈS les trois autres : elle ne dit rien d'une suite qui n'est pas
# déjà verte. Sans M= elle mute tout le noyau ; avec, seulement le module que la
# carte a touché — cf. .claude/workflows/carte-du-noyau.md, phase 6, qui écrit
# aussi le prix de ce filtre : une régression causée ailleurs y échapperait.
#
# --no-shuffle : l'ordre des mutations est stable d'une exécution à l'autre,
# pour la même raison que le noyau l'est.
#
# Le garde-fou du vide, ajouté après l'avoir vu manquer : un filtre M= qui ne
# correspond à aucun fichier fait dire « 0 mutants » à cargo-mutants, qui sort
# alors en 0. La cible annonçait « MUTATION : OK » sans avoir muté quoi que ce
# soit — le cinquième « OK sans rien vérifier » de ce dépôt, évité avant d'être
# commis. Un compte nul est désormais un échec, code 2.
check-mutations:
	@command -v cargo-mutants >/dev/null || \
	  { echo "cargo-mutants introuvable — cargo install cargo-mutants --locked"; exit 1; }
	@( cd app/core && cargo mutants -d kernel --no-shuffle $(if $(M),-f "$(M)",) ) \
	  > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^(MISSED|TIMEOUT|[0-9]+ mutants tested)" "$(JOURNAL)" || true; \
	if ! grep -qE "^[1-9][0-9]* mutants tested" "$(JOURNAL)"; then \
	  echo "MUTATION : ÉCHEC — aucune mutation produite, la vérification n'a rien vérifié"; \
	  exit 2; \
	fi; \
	if [ $$code -ne 0 ]; then \
	  echo "MUTATION : ÉCHEC — une mutation a survécu, donc un test manque"; \
	else \
	  echo "MUTATION : OK"; \
	fi; \
	exit $$code

# Même filtrage que check-integrity, et pour la même raison : le code de sortie
# vient de Godot, pas du grep.
# Les tests du noyau Rust d'abord : ils répondent à la même question — « le code
# répond-il juste ? » — dans l'autre langue. Une cible séparée découperait ce qui
# ne se découpe pas.
test-behaviour: godot import
	@CARGO_TARGET_DIR=$(CARGO_TARGET) cargo test --manifest-path app/core/Cargo.toml \
	  -p bbtrainer_kernel --quiet 2>&1 | grep -E "^(test result|error|---- )" || true
	@CARGO_TARGET_DIR=$(CARGO_TARGET) cargo test --manifest-path app/core/Cargo.toml \
	  -p bbtrainer_kernel --quiet > /dev/null 2>&1 || { echo "NOYAU RUST : ÉCHEC"; exit 1; }
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_behaviour.gd \
	  > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^\[(ok|KO|note|----|####)\]" "$(JOURNAL)" || true; \
	grep -E "SCRIPT ERROR|godot-rust function call failed" "$(JOURNAL)" || true; \
	if grep -qE "SCRIPT ERROR|godot-rust function call failed" "$(JOURNAL)"; then \
	  echo "TESTS DE COMPORTEMENT : ÉCHEC — une erreur moteur a été levée pendant les tests"; \
	  exit 1; \
	fi; \
	if [ $$code -ne 0 ]; then \
	  echo "TESTS DE COMPORTEMENT : ÉCHEC — sortie complète dans $(JOURNAL)"; \
	else \
	  echo "TESTS DE COMPORTEMENT : OK"; \
	fi; \
	exit $$code

test: check-integrity test-behaviour

verbeux: godot
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_tests.gd -- $(V)

journal:
	@test -f "$(JOURNAL)" && cat "$(JOURNAL)" || echo "Aucune exécution enregistrée."
