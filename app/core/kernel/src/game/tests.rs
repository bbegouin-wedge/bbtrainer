//! Les règles de la phase 2, une par une.
//!
//! Écrits contre des corps `todo!()`, donc vus échouer avant d'être vus passer.
//! Les tests d'attente utilisent l'échafaudage `Ask` / `Answer` : aucune règle
//! ne produit encore de question, et la carte 16 remplacera cette paire par les
//! vraies — choix du dé de blocage, direction de poussée, suivi, relance.

use super::*;
use crate::dice::Die;

const GRAINE: u64 = 1789;

// ---------------------------------------------------------------------------
// J1 — deux équipes, un tour appartient à l'une
// ---------------------------------------------------------------------------

#[test]
fn chaque_camp_a_un_autre() {
    assert_eq!(Team::Blue.other(), Team::Red);
    assert_eq!(Team::Red.other(), Team::Blue);
}

#[test]
fn un_match_neuf_attend_le_bleu_au_tour_zero() {
    let m = Match::new(GRAINE);

    assert_eq!(m.to_act(), Team::Blue);
    assert_eq!(m.turn(), 0);
    assert_eq!(m.pending(), None);
}

#[test]
fn finir_son_tour_passe_la_main() {
    let mut m = Match::new(GRAINE);

    let faits = m.submit(Team::Blue, Command::EndTurn).unwrap();

    assert_eq!(
        faits,
        vec![Event::TurnEnded {
            team: Team::Blue,
            turn: 0
        }]
    );
    assert_eq!(m.to_act(), Team::Red);
    assert_eq!(m.turn(), 1);
}

// ---------------------------------------------------------------------------
// Le refus — et surtout ce qu'il ne fait pas
// ---------------------------------------------------------------------------

#[test]
fn une_commande_du_mauvais_entraineur_est_refusee() {
    let mut m = Match::new(GRAINE);

    assert_eq!(
        m.submit(Team::Red, Command::EndTurn),
        Err(Rejected::WrongCoach)
    );
}

/// **A3.** Un journal rejoué doit reproduire la partie exactement ; si un refus
/// laissait la moindre trace, il divergerait sur une commande illégale.
#[test]
fn un_refus_ne_mute_rien() {
    let mut m = Match::new(GRAINE);
    let (avant_tour, avant_actif, avant_attente) = (m.turn(), m.to_act(), m.pending());

    let _ = m.submit(Team::Red, Command::EndTurn);

    assert_eq!(m.turn(), avant_tour);
    assert_eq!(m.to_act(), avant_actif);
    assert_eq!(m.pending(), avant_attente);
}

#[test]
fn hors_attente_les_commandes_ordinaires_sont_legales() {
    let m = Match::new(GRAINE);

    assert_eq!(m.legal_commands(), vec![Command::EndTurn, Command::Ask]);
}

// ---------------------------------------------------------------------------
// J2, J3 — l'attente nomme son entraîneur, et ce n'est pas l'actif
// ---------------------------------------------------------------------------

/// **Le test qui justifie la conception de `Pending`.** L'échafaudage interroge
/// l'adversaire exprès : une implémentation qui déduirait le propriétaire d'une
/// décision du tour courant passerait si la question revenait à l'actif. À
/// Blood Bowl elle ne lui revient pas — la case d'une poussée est choisie par
/// l'entraîneur adverse, et `SIDESTEP` la rend au poussé.
#[test]
fn l_attente_nomme_un_entraineur_qui_n_est_pas_l_actif() {
    let mut m = Match::new(GRAINE);

    m.submit(Team::Blue, Command::Ask).unwrap();

    assert_eq!(
        m.pending(),
        Some(Pending {
            coach: Team::Red,
            question: Question::Confirm
        })
    );
    assert_eq!(m.to_act(), Team::Red, "c'est l'adversaire qu'on attend");
}

#[test]
fn en_attente_seules_les_reponses_sont_legales() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::Ask).unwrap();

    let jouables = m.legal_commands();

    assert_eq!(jouables, vec![Command::Answer(true), Command::Answer(false)]);
    assert!(
        !jouables.contains(&Command::EndTurn),
        "aucune commande ordinaire ne passe tant que la question tient"
    );
}

#[test]
fn en_attente_une_commande_ordinaire_est_refusee() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::Ask).unwrap();

    assert_eq!(
        m.submit(Team::Red, Command::EndTurn),
        Err(Rejected::NotLegal)
    );
}

/// Celui dont c'est le tour n'est pas celui qu'on attend : il ne peut pas
/// répondre à la place de l'autre.
#[test]
fn l_entraineur_non_attendu_ne_peut_pas_repondre() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::Ask).unwrap();

    assert_eq!(
        m.submit(Team::Blue, Command::Answer(true)),
        Err(Rejected::WrongCoach)
    );
}

#[test]
fn repondre_ferme_l_attente_et_rend_la_parole() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::Ask).unwrap();

    let faits = m.submit(Team::Red, Command::Answer(true)).unwrap();

    assert_eq!(
        faits,
        vec![Event::Answered {
            coach: Team::Red,
            yes: true
        }]
    );
    assert_eq!(m.pending(), None);
    assert_eq!(m.to_act(), Team::Blue, "le tour n'a pas changé de mains");
    assert_eq!(m.turn(), 0);
}

/// La réponse négative referme l'attente aussi. Un test à part, parce qu'une
/// implémentation qui n'effacerait l'attente que sur « oui » passerait l'autre.
#[test]
fn repondre_non_ferme_l_attente_aussi() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::Ask).unwrap();

    let faits = m.submit(Team::Red, Command::Answer(false)).unwrap();

    assert_eq!(
        faits,
        vec![Event::Answered {
            coach: Team::Red,
            yes: false
        }]
    );
    assert_eq!(m.pending(), None);
}

// ---------------------------------------------------------------------------
// A2 — le déroulé refait ses dés au lieu de les copier
// ---------------------------------------------------------------------------

/// **Le garde-fou de A5, celui qui empêche l'agent de connaître l'avenir.**
///
/// Le déroulé est forké avec la MÊME graine que le match, après que celui-ci a
/// consommé des dés. Si `fork_for_rollout` copiait les réserves, le déroulé
/// reprendrait au curseur du match et verrait donc la suite qui va réellement
/// sortir. Il doit au contraire repartir du début de sa propre suite.
#[test]
fn un_deroule_refait_ses_des_au_lieu_de_les_copier() {
    let mut m = Match::new(GRAINE);
    let deja_sortis: Vec<u8> = (0..5).map(|_| m.dice.roll(Die::D6)).collect();

    let mut deroule = m.fork_for_rollout(GRAINE);
    let vus_par_le_deroule: Vec<u8> = (0..5).map(|_| deroule.dice.roll(Die::D6)).collect();

    assert_eq!(
        vus_par_le_deroule, deja_sortis,
        "le déroulé doit repartir du début de sa suite, pas du curseur du match"
    );
}

/// Une graine de déroulé différente donne d'autres dés — c'est ce qui rendra
/// plusieurs déroulés d'une même intention représentatifs.
#[test]
fn deux_deroules_de_graines_differentes_voient_d_autres_des() {
    let m = Match::new(GRAINE);

    let mut a = m.fork_for_rollout(1);
    let mut b = m.fork_for_rollout(2);

    let sa: Vec<u8> = (0..10).map(|_| a.dice.roll(Die::D6)).collect();
    let sb: Vec<u8> = (0..10).map(|_| b.dice.roll(Die::D6)).collect();
    assert_ne!(sa, sb);
}

/// Tout le reste est bien copié : sans quoi le déroulé simulerait une autre
/// partie que celle en cours.
#[test]
fn un_deroule_copie_tout_sauf_les_des() {
    let mut m = Match::new(GRAINE);
    m.submit(Team::Blue, Command::EndTurn).unwrap();
    m.submit(Team::Red, Command::Ask).unwrap();

    let deroule = m.fork_for_rollout(99);

    assert_eq!(deroule.turn(), m.turn());
    assert_eq!(deroule.to_act(), m.to_act());
    assert_eq!(deroule.pending(), m.pending());
}
