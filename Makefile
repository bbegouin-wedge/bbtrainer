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

# Vérification à lancer seule : make check-integrity V=scenes
V ?=

.PHONY: help run debug editeur check-integrity check-arch test-unit test verbeux godot import journal

help:
	@echo "Cibles :"
	@echo "  make run                  lance le jeu"
	@echo "  make debug                idem, avec le débogueur stdout et le mode verbeux"
	@echo "  make editeur              ouvre l'éditeur (seul endroit avec points d'arrêt)"
	@echo "  make check-integrity      intégrité de tout le projet (10 vérifications)"
	@echo "  make check-integrity V=x  une seule : project | pairing | classes |"
	@echo "                            scripts | resources | json | scenes |"
	@echo "                            references | data_assets | architecture"
	@echo "  make verbeux              idem, sortie moteur brute et non filtrée"
	@echo "  make check-arch           les seules règles d'architecture (core/)"
	@echo "  make test-unit            les tests unitaires de tests/unit/"
	@echo "  make test                 intégrité + tests unitaires"
	@echo "  make import               réimporte les assets (une fois après un clone)"
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

run: godot
	@"$(GODOT)" --path "$(CURDIR)" $(ARGS)

# Jeu + débogueur stdout local et sortie verbeuse. Les aides visuelles se
# demandent par ARGS, elles sont trop bavardes pour être posées par défaut :
#   make debug ARGS="--debug-collisions"            les Area2D des unités
#   make debug ARGS="--debug-canvas-item-redraw"    chaque _draw() clignote
debug: godot
	@"$(GODOT)" --path "$(CURDIR)" -d --verbose $(ARGS)

# L'éditeur — seul endroit où les points d'arrêt existent. Pour attacher un jeu
# lancé par `make run` à un éditeur ouvert :
#   make run ARGS="--remote-debug tcp://127.0.0.1:6007"
editeur: godot
	@"$(GODOT)" --path "$(CURDIR)" -e

import: godot
	@"$(GODOT)" --headless --path "$(CURDIR)" --import

# La sortie brute du moteur contient 199 lignes d'erreurs préexistantes
# (TileSet, shader) qui ne sont pas des échecs : le rapport est donc préfixé par
# le harnais, et seul ce préfixe est affiché. Le code de sortie vient de Godot,
# jamais du grep — un grep sans correspondance sort en 1 et déguiserait un
# succès en échec.
check-integrity: godot
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
check-arch:
	@$(MAKE) --no-print-directory check-integrity V=architecture

# Même filtrage que check-integrity, et pour la même raison : le code de sortie
# vient de Godot, pas du grep.
test-unit: godot
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_unit.gd \
	  > "$(JOURNAL)" 2>&1; code=$$?; \
	grep -E "^\[(ok|KO|note|----|####)\]" "$(JOURNAL)" || true; \
	grep -E "SCRIPT ERROR" "$(JOURNAL)" || true; \
	if [ $$code -ne 0 ]; then \
	  echo "TESTS UNITAIRES : ÉCHEC — sortie complète dans $(JOURNAL)"; \
	else \
	  echo "TESTS UNITAIRES : OK"; \
	fi; \
	exit $$code

test: check-integrity test-unit

verbeux: godot
	@"$(GODOT)" --headless --path "$(CURDIR)" --script res://tests/run_tests.gd -- $(V)

journal:
	@test -f "$(JOURNAL)" && cat "$(JOURNAL)" || echo "Aucune exécution enregistrée."
