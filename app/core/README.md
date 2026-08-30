# `app/core/` — le noyau

Les règles et le modèle du jeu. **Vide aujourd'hui** : son contenu est encore
mêlé aux scripts d'écran, et sera extrait au fil des chantiers (cf. CLAUDE.md,
« Organisation cible » et « Comment on y va »).

Deux interdits, vérifiés par `make check-arch` :

1. **Aucun `Node`.** C'est ce qui rend le noyau vérifiable sans fenêtre — et
   donc testable. Le contrôle porte sur le type natif résolu : hériter d'un
   script de `core/` qui hérite de `Node` est vu aussi.
2. **Aucune dépendance hors de `core/`.** Ni chemin `res://` extérieur, ni
   autoload, ni `class_name` déclaré ailleurs. GDScript n'ayant pas d'espace de
   noms, rien n'empêche ces appels : c'est le vérificateur qui les rend visibles.

Ce qui reste permis : les types natifs du moteur (`RefCounted`, `Resource`,
`Vector2i`, `Color`…). Ce sont des primitives, pas des dépendances de projet.
