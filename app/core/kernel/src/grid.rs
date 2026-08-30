//! Modèle logique d'une zone : quelle unité occupe quelle case.
//!
//! Portage de `app/core/rules/unit_grid.gd`. Trois écarts avec l'original, et
//! chacun a sa raison :
//!
//! - la grille est indexée par des **identifiants** et non par des nœuds Godot :
//!   un noyau qui garderait des nœuds connaîtrait le moteur ;
//! - elle **rend des événements** au lieu d'émettre un signal — c'est la forme
//!   que décrit `docs/noyau-et-apprenant.html`, et c'est ce qui permet à la
//!   liaison de reproduire fidèlement le comportement observable ;
//! - elle ignore `Vector2i` : `Tile` est local, converti à la frontière.

use std::collections::HashMap;

/// Une case, en coordonnées de grille. Aucun pixel ici.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub struct Tile {
    pub x: i32,
    pub y: i32,
}

impl Tile {
    pub fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }
}

/// Identifiant opaque d'une unité.
///
/// Le noyau ne sait pas ce que ce nombre désigne — c'est la liaison qui tient la
/// correspondance avec les nœuds du moteur. Reprendre ici l'identifiant
/// d'instance de Godot aurait simplifié la frontière, au prix d'un noyau qui
/// porte la trace de son adaptateur.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
pub struct UnitId(u64);

impl UnitId {
    pub fn new(raw: u64) -> Self {
        Self(raw)
    }
}

/// Ce qu'une mutation a réellement produit.
///
/// Déplacer une unité rend `[Left, Landed]` : c'est ce qui permet à la liaison
/// d'émettre deux fois `unit_grid_changed`, comme le fait le GDScript
/// d'aujourd'hui — un comportement figé par les tests de caractérisation, et
/// qu'il fallait pouvoir reproduire sans le deviner.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum GridEvent {
    Left { unit: UnitId, tile: Tile },
    Landed { unit: UnitId, tile: Tile },
    Cleared,
}

#[derive(Debug)]
pub struct Grid {
    size: Tile,
    unit_by_tile: HashMap<Tile, UnitId>,
    tile_by_unit: HashMap<UnitId, Tile>,
}

impl Grid {
    pub fn new(size: Tile) -> Self {
        Self {
            size,
            unit_by_tile: HashMap::new(),
            tile_by_unit: HashMap::new(),
        }
    }

    pub fn size(&self) -> Tile {
        self.size
    }

    /// Place l'unité, en la retirant d'abord de sa case précédente.
    pub fn place(&mut self, unit: UnitId, tile: Tile) -> Vec<GridEvent> {
        let mut events = self.remove(unit);
        self.unit_by_tile.insert(tile, unit);
        self.tile_by_unit.insert(unit, tile);
        events.push(GridEvent::Landed { unit, tile });
        events
    }

    /// Retirer une unité absente ne fait rien et ne rend aucun événement.
    pub fn remove(&mut self, unit: UnitId) -> Vec<GridEvent> {
        let Some(tile) = self.tile_by_unit.remove(&unit) else {
            return Vec::new();
        };
        self.unit_by_tile.remove(&tile);
        vec![GridEvent::Left { unit, tile }]
    }

    pub fn unit_at(&self, tile: Tile) -> Option<UnitId> {
        self.unit_by_tile.get(&tile).copied()
    }

    pub fn is_occupied(&self, tile: Tile) -> bool {
        self.unit_by_tile.contains_key(&tile)
    }

    /// Reposer une unité sur sa propre case n'est pas une collision.
    pub fn is_blocked_for(&self, tile: Tile, unit: UnitId) -> bool {
        matches!(self.unit_by_tile.get(&tile), Some(&occupant) if occupant != unit)
    }

    pub fn has_unit(&self, unit: UnitId) -> bool {
        self.tile_by_unit.contains_key(&unit)
    }

    pub fn tile_of(&self, unit: UnitId) -> Option<Tile> {
        self.tile_by_unit.get(&unit).copied()
    }

    pub fn occupied_tiles(&self) -> Vec<Tile> {
        self.unit_by_tile.keys().copied().collect()
    }

    pub fn clear(&mut self) -> Vec<GridEvent> {
        self.unit_by_tile.clear();
        self.tile_by_unit.clear();
        vec![GridEvent::Cleared]
    }
}

#[cfg(test)]
mod tests;
