//! Les mêmes invariants que `tests/unit/unit_grid_test.gd`, portés en Rust.
//!
//! Ils figent le comportement observable du GDScript d'aujourd'hui — c'est ce
//! qui rendra le portage démontrable quand la liaison arrivera (carte 9) : les
//! neuf tests de comportement devront passer sans être modifiés.

use super::*;

fn grille() -> Grid {
    Grid::new(Tile::new(26, 15))
}

fn unite(n: u64) -> UnitId {
    UnitId::new(n)
}

/// Reposer une unité ailleurs la déplace : rien ne reste sur l'ancienne case.
#[test]
fn poser_deplace_au_lieu_de_dupliquer() {
    let mut g = grille();
    let u = unite(1);
    g.place(u, Tile::new(1, 1));
    g.place(u, Tile::new(4, 2));

    assert_eq!(g.unit_at(Tile::new(1, 1)), None, "l'ancienne case est libérée");
    assert_eq!(g.unit_at(Tile::new(4, 2)), Some(u));
    assert_eq!(g.tile_of(u), Some(Tile::new(4, 2)), "l'index inverse suit");
    assert_eq!(g.occupied_tiles().len(), 1, "une seule case occupée");
}

/// La subtilité que le commentaire de `is_tile_blocked_for` signalait.
#[test]
fn sa_propre_case_ne_bloque_pas() {
    let mut g = grille();
    let (u, autre) = (unite(1), unite(2));
    g.place(u, Tile::new(3, 3));

    assert!(!g.is_blocked_for(Tile::new(3, 3), u));
    assert!(g.is_blocked_for(Tile::new(3, 3), autre));
    assert!(g.is_occupied(Tile::new(3, 3)));
}

/// L'index inverse est celui qui pourrit en silence.
#[test]
fn vider_vide_les_deux_index() {
    let mut g = grille();
    let u = unite(1);
    g.place(u, Tile::new(2, 2));
    g.clear();

    assert_eq!(g.unit_at(Tile::new(2, 2)), None);
    assert!(!g.has_unit(u));
    assert!(g.occupied_tiles().is_empty());
}

/// Un déplacement rend DEUX événements — c'est ce qui permettra à la liaison
/// d'émettre `unit_grid_changed` deux fois, comme le GDScript le fait.
#[test]
fn les_evenements_rendus_disent_ce_qui_s_est_passe() {
    let mut g = grille();
    let u = unite(1);

    assert_eq!(
        g.place(u, Tile::new(0, 0)),
        vec![GridEvent::Landed { unit: u, tile: Tile::new(0, 0) }],
        "un seul événement à la pose"
    );
    assert_eq!(
        g.place(u, Tile::new(1, 0)),
        vec![
            GridEvent::Left { unit: u, tile: Tile::new(0, 0) },
            GridEvent::Landed { unit: u, tile: Tile::new(1, 0) },
        ],
        "deux au déplacement : le départ puis l'arrivée"
    );
    assert_eq!(
        g.remove(u),
        vec![GridEvent::Left { unit: u, tile: Tile::new(1, 0) }],
        "un au retrait"
    );
    assert_eq!(g.clear(), vec![GridEvent::Cleared], "un au vidage");
}

/// Retirer une unité absente ne fait rien ET ne rend aucun événement : un
/// abonné qui se redessine à chaque événement le paierait autrement.
#[test]
fn retirer_une_unite_absente_est_silencieux() {
    let mut g = grille();
    assert!(g.remove(unite(7)).is_empty());
}

#[test]
fn une_grille_vide_ne_repond_rien() {
    let g = grille();
    assert_eq!(g.unit_at(Tile::new(9, 9)), None);
    assert!(!g.is_occupied(Tile::new(9, 9)));
    assert!(!g.has_unit(unite(1)));
    assert_eq!(g.size(), Tile::new(26, 15));
}
