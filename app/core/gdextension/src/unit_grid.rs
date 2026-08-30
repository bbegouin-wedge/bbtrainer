//! La grille, exposée à GDScript.
//!
//! Cette classe ne contient aucune règle : elle traduit. Le noyau parle en
//! identifiants opaques et en événements ; GDScript parle en nœuds et en
//! signaux. Tout ce qui suit est cette traduction, et rien d'autre.
//!
//! **Aucun `Gd<Node>` n'est conservé.** La table garde des `InstanceId` et les
//! résout à la demande : un nœud libéré redevient simplement introuvable, là où
//! une poignée gardée serait pendante.

use bbtrainer_kernel::{Grid, GridEvent, Tile, UnitId};
use godot::classes::Node;
use godot::prelude::*;
use std::collections::HashMap;

#[derive(GodotClass)]
#[class(base=RefCounted)]
pub struct UnitGrid {
    grid: Grid,
    /// Correspondance dans les deux sens entre les nœuds du moteur et les
    /// identifiants du noyau. C'est la seule chose que la frontière ajoute.
    id_by_node: HashMap<i64, UnitId>,
    node_by_id: HashMap<UnitId, i64>,
    next_id: u64,
    /// Miroir de la taille du noyau, pour que GDScript la lise en propriété —
    /// `unit_zone.gd` fait `Rect2i(Vector2i.ZERO, grid.size)`. Elle ne change
    /// jamais après la construction.
    #[var]
    size: Vector2i,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for UnitGrid {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            grid: Grid::new(Tile::new(0, 0)),
            id_by_node: HashMap::new(),
            node_by_id: HashMap::new(),
            next_id: 0,
            size: Vector2i::ZERO,
            base,
        }
    }
}

#[godot_api]
impl UnitGrid {
    #[signal]
    fn unit_grid_changed();

    /// `new()` ne prend pas d'argument — c'est le protocole d'instanciation de
    /// Godot, pas une limite de gdext. D'où cette fabrique, qui interdit qu'une
    /// grille existe un instant sans sa taille.
    #[func]
    fn create(size: Vector2i) -> Gd<UnitGrid> {
        let mut grid = UnitGrid::new_gd();
        {
            let mut inner = grid.bind_mut();
            inner.grid = Grid::new(Tile::new(size.x, size.y));
            inner.size = size;
        }
        grid
    }

    /// Seule méthode qui refuse le nul, et délibérément : le GDScript aurait
    /// rangé `null` dans ses deux index, corrompant la grille en silence.
    /// Aucun appelant ne le fait ; échouer bruyamment vaut mieux.
    #[func]
    fn place_unit(&mut self, tile: Vector2i, unit: Gd<Node>) {
        let id = self.identify(&unit);
        let events = self.grid.place(id, to_tile(tile));
        self.announce(events);
    }

    /// Retirer « rien » ne fait rien, comme le GDScript le faisait.
    #[func]
    fn remove_unit(&mut self, unit: Option<Gd<Node>>) {
        let Some(&id) = unit.and_then(|u| self.id_by_node.get(&instance_of(&u))) else {
            return;
        };
        let events = self.grid.remove(id);
        self.announce(events);
    }

    #[func]
    fn get_unit_at(&self, tile: Vector2i) -> Option<Gd<Node>> {
        self.grid.unit_at(to_tile(tile)).and_then(|id| self.node(id))
    }

    #[func]
    fn is_tile_occupied(&self, tile: Vector2i) -> bool {
        self.grid.is_occupied(to_tile(tile))
    }

    /// L'unité peut être nulle, et ce n'est pas un cas dégénéré : `arena.gd`
    /// demande « cette case est-elle libre ? » AVANT de créer le jeton, donc
    /// pour une unité qui n'existe pas encore. La réponse est alors « bloquée
    /// si occupée par qui que ce soit ».
    #[func]
    fn is_tile_blocked_for(&self, tile: Vector2i, unit: Option<Gd<Node>>) -> bool {
        match unit.and_then(|u| self.id_by_node.get(&instance_of(&u)).copied()) {
            Some(id) => self.grid.is_blocked_for(to_tile(tile), id),
            None => self.grid.is_occupied(to_tile(tile)),
        }
    }

    #[func]
    fn has_unit(&self, unit: Option<Gd<Node>>) -> bool {
        match unit.and_then(|u| self.id_by_node.get(&instance_of(&u)).copied()) {
            Some(id) => self.grid.has_unit(id),
            None => false,
        }
    }

    /// Rend `Vector2i.ZERO` pour une unité absente : le GDScript le faisait, et
    /// son commentaire disait « à n'appeler qu'après has_unit() ».
    #[func]
    fn get_tile_of(&self, unit: Option<Gd<Node>>) -> Vector2i {
        unit.and_then(|u| self.id_by_node.get(&instance_of(&u)).copied())
            .and_then(|id| self.grid.tile_of(id))
            .map(|t| Vector2i::new(t.x, t.y))
            .unwrap_or(Vector2i::ZERO)
    }

    #[func]
    fn get_occupied_tiles(&self) -> Array<Vector2i> {
        self.grid
            .occupied_tiles()
            .into_iter()
            .map(|t| Vector2i::new(t.x, t.y))
            .collect()
    }

    #[func]
    fn clear(&mut self) {
        let events = self.grid.clear();
        self.id_by_node.clear();
        self.node_by_id.clear();
        self.announce(events);
    }
}

impl UnitGrid {
    /// Attribue un identifiant au nœud, ou retrouve le sien.
    fn identify(&mut self, unit: &Gd<Node>) -> UnitId {
        let instance = instance_of(unit);
        if let Some(&id) = self.id_by_node.get(&instance) {
            return id;
        }
        let id = UnitId::new(self.next_id);
        self.next_id += 1;
        self.id_by_node.insert(instance, id);
        self.node_by_id.insert(id, instance);
        id
    }

    fn node(&self, id: UnitId) -> Option<Gd<Node>> {
        let instance = *self.node_by_id.get(&id)?;
        Gd::try_from_instance_id(InstanceId::from_i64(instance)).ok()
    }

    /// Un signal par événement rendu par le noyau : c'est ce qui reproduit les
    /// deux émissions d'un déplacement, que les tests de caractérisation ont
    /// figées.
    fn announce(&mut self, events: Vec<GridEvent>) {
        for _ in events {
            self.signals().unit_grid_changed().emit();
        }
    }
}

fn to_tile(v: Vector2i) -> Tile {
    Tile::new(v.x, v.y)
}

fn instance_of(unit: &Gd<Node>) -> i64 {
    unit.instance_id().to_i64()
}
