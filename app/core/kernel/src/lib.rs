//! Les règles du jeu, sans le moteur.
//!
//! Ce crate ne dépend pas de `godot`, et c'est vérifié par le compilateur plutôt
//! que par une convention : rien ici ne peut appeler le moteur, ni lire un
//! fichier, ni connaître un pixel.

pub mod grid;

pub use grid::{Grid, GridEvent, Tile, UnitId};
