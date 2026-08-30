//! Empreinte d'un scénario, pour comparer deux exécutions.
//!
//! Le test ne vérifie rien à lui seul : il imprime. C'est `make check-arch` qui
//! le lance **dans deux processus** et compare les sorties.
//!
//! Deux processus, et pas deux appels dans le même : `HashMap` ne sème son
//! hachage qu'une fois par processus, si bien qu'une double exécution locale
//! aurait donné deux fois le même ordre — et laissé passer un noyau non
//! déterministe.
//!
//! Sa portée est celle de son scénario. Il ne prouve pas que tout le noyau est
//! déterministe ; il prouve que ce qu'il exerce l'est, et attrapera n'importe
//! quelle cause future — horloge, générateur non semé, structure non ordonnée.

use bbtrainer_kernel::{Command, Dice, Die, Grid, GridEvent, Match, Team, Tile, UnitId};

/// Fixe : c'est le principe même de l'empreinte.
const GRAINE_DES: u64 = 20_260_830;
const GRAINE_MATCH: u64 = 1_312;

fn trace(events: &[GridEvent]) -> String {
    events
        .iter()
        .map(|e| match e {
            GridEvent::Left { unit, tile } => format!("L{:?}{},{}", unit, tile.x, tile.y),
            GridEvent::Landed { unit, tile } => format!("A{:?}{},{}", unit, tile.x, tile.y),
            GridEvent::Cleared => "C".to_string(),
        })
        .collect::<Vec<_>>()
        .join("|")
}

#[test]
fn imprimer_l_empreinte() {
    let mut grid = Grid::new(Tile::new(26, 15));
    let mut morceaux: Vec<String> = Vec::new();

    for i in 0..12u64 {
        let unite = UnitId::new(i * 7 % 13);
        let case = Tile::new((i * 5 % 26) as i32, (i * 3 % 15) as i32);
        morceaux.push(trace(&grid.place(unite, case)));
    }
    morceaux.push(trace(&grid.remove(UnitId::new(7))));
    morceaux.push(
        grid.occupied_tiles()
            .iter()
            .map(|t| format!("{},{}", t.x, t.y))
            .collect::<Vec<_>>()
            .join(" "),
    );
    morceaux.push(trace(&grid.clear()));

    // Les dés, ajoutés par la carte 13. Le scénario doit suivre l'état du noyau :
    // une réserve semée par l'horloge ou par le générateur du système passerait
    // inaperçue si l'empreinte ne regardait que la grille — le contrôle
    // resterait vert en couvrant une part décroissante du noyau.
    let mut dice = Dice::new(GRAINE_DES);
    for die in Die::ALL {
        let tirages = (0..8)
            .map(|_| dice.roll(die).to_string())
            .collect::<Vec<_>>()
            .join(",");
        morceaux.push(format!("{die:?}={tirages}"));
    }

    // Le match, ajouté par la carte 14. Même motif que pour les dés : le
    // scénario doit suivre l'état du noyau, sinon le contrôle couvre une part
    // décroissante de ce qu'il prétend garantir, en restant vert.
    //
    // La suite exerce les deux natures de refus et les deux d'événement, pour
    // que l'empreinte change si l'une d'elles se met à répondre autrement.
    let mut partie = Match::new(GRAINE_MATCH);
    let scenario = [
        (Team::Blue, Command::EndTurn),
        (Team::Red, Command::Ask),
        (Team::Red, Command::EndTurn),
        (Team::Blue, Command::Answer(true)),
        (Team::Blue, Command::EndTurn),
        (Team::Red, Command::EndTurn),
    ];
    for (par, commande) in scenario {
        morceaux.push(format!("{:?}", partie.submit(par, commande)));
    }
    morceaux.push(format!("T{}/{:?}", partie.turn(), partie.to_act()));

    println!("EMPREINTE={}", morceaux.join(" / "));
}
