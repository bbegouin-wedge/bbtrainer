//! Le noyau, et sa porte vers Godot.
//!
//! Ce lot ne contient aucune règle de jeu : il n'existe que pour prouver que la
//! chaîne tient — cargo compile, Godot charge, GDScript appelle.

use godot::prelude::*;

mod unit_grid;

struct BbTrainerExtension;

#[gdextension]
unsafe impl ExtensionLibrary for BbTrainerExtension {}

/// Seul point d'entrée exposé pour l'instant. Sa version permet au harnais de
/// vérifier non pas que le fichier existe, mais que Godot l'a bien chargé.
#[derive(GodotClass)]
#[class(base=RefCounted, init)]
pub struct BbCore {}

#[godot_api]
impl BbCore {
    #[func]
    fn version(&self) -> GString {
        GString::from(env!("CARGO_PKG_VERSION"))
    }
}
