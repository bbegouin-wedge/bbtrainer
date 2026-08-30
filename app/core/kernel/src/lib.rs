//! Les règles du jeu, sans le moteur.
//!
//! Ce crate ne dépend pas de `godot`, et c'est vérifié par le compilateur plutôt
//! que par une convention : rien ici ne peut appeler le moteur, ni lire un
//! fichier, ni connaître un pixel.

pub mod dice;
pub mod game;
pub mod grid;

pub use dice::{Dice, Die};
pub use game::{Command, Event, Match, Pending, Question, Rejected, Team};
pub use grid::{Grid, GridEvent, Tile, UnitId};
