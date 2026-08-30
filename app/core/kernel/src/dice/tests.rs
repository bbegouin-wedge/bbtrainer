//! Les règles de la phase 2, une par une.
//!
//! Écrits contre des corps `todo!()`, donc vus échouer avant d'être vus passer.
//! Un test qui aurait été vert à ce moment-là n'appelait rien, donc ne vérifiait
//! rien — c'est le seul moment où on peut le savoir sans effort.

use super::*;

const GRAINE: u64 = 1789;

fn suite(dice: &mut Dice, die: Die, n: usize) -> Vec<u8> {
    (0..n).map(|_| dice.roll(die)).collect()
}

// ---------------------------------------------------------------------------
// J1, J2 — les six types, uniformes sur leurs faces
// ---------------------------------------------------------------------------

/// Le nombre de faces de chaque type est celui du livre de règles, et aucun
/// tirage n'en sort. Le zéro est aussi une faute qu'on veut voir : un dé
/// commence à 1.
#[test]
fn chaque_de_tire_dans_ses_faces() {
    let attendu = [
        (Die::D3, 3u8),
        (Die::D6, 6),
        (Die::Block, 6),
        (Die::D8, 8),
        (Die::D12, 12),
        (Die::D16, 16),
    ];
    let mut dice = Dice::new(GRAINE);

    for (die, faces) in attendu {
        for v in suite(&mut dice, die, 500) {
            assert!(
                (1..=faces).contains(&v),
                "{die:?} a rendu {v}, hors de 1..={faces}"
            );
        }
    }
}

/// Chaque face sort, et à peu près autant que les autres. Graine fixée, donc
/// aucun risque d'échec intermittent : c'est toujours le même tirage.
#[test]
fn le_d6_est_uniforme() {
    let mut dice = Dice::new(GRAINE);
    let mut compte = [0usize; 6];
    let tirages = 60_000;

    for v in suite(&mut dice, Die::D6, tirages) {
        compte[(v - 1) as usize] += 1;
    }

    let attendu = tirages / 6;
    let marge = attendu / 20; // 5 %
    for (face, n) in compte.iter().enumerate() {
        assert!(
            n.abs_diff(attendu) < marge,
            "la face {} est sortie {n} fois, attendu ~{attendu}",
            face + 1
        );
    }
}

// ---------------------------------------------------------------------------
// A1 — même graine, même suite
// ---------------------------------------------------------------------------

/// La propriété qui fonde le journal, le rejeu et le corpus de non-régression.
#[test]
fn meme_graine_meme_suite() {
    let mut a = Dice::new(GRAINE);
    let mut b = Dice::new(GRAINE);

    for die in Die::ALL {
        assert_eq!(
            suite(&mut a, die, 50),
            suite(&mut b, die, 50),
            "{die:?} diverge entre deux dés de même graine"
        );
    }
}

/// Sans quoi la graine ne servirait à rien — et le stratège, qui tirera sa
/// propre graine pour ses déroulés, verrait les dés du match.
#[test]
fn graines_differentes_suites_differentes() {
    let mut a = Dice::new(GRAINE);
    let mut b = Dice::new(GRAINE + 1);

    assert_ne!(suite(&mut a, Die::D6, 50), suite(&mut b, Die::D6, 50));
}

// ---------------------------------------------------------------------------
// A2 — le cloisonnement par type
// ---------------------------------------------------------------------------

/// **Le test qui justifie toute la conception.** Consommer des d8 ne doit rien
/// changer aux d6 qui suivent : c'est ce qui fait qu'ajouter demain une règle de
/// déviation ne décalera pas les esquives des parties déjà enregistrées.
#[test]
fn consommer_un_type_n_en_decale_aucun_autre() {
    let temoin = suite(&mut Dice::new(GRAINE), Die::D6, 20);

    let mut perturbe = Dice::new(GRAINE);
    suite(&mut perturbe, Die::D8, 7);
    suite(&mut perturbe, Die::D16, 3);
    suite(&mut perturbe, Die::Block, 11);

    assert_eq!(
        temoin,
        suite(&mut perturbe, Die::D6, 20),
        "des tirages d'autres types ont décalé la suite des d6"
    );
}

/// Le dé de blocage a six faces comme le d6, et c'est justement pourquoi il lui
/// faut sa propre réserve : sans elle, ce serait la même suite deux fois.
#[test]
fn le_de_de_blocage_n_est_pas_le_d6() {
    let mut dice = Dice::new(GRAINE);
    let d6 = suite(&mut dice, Die::D6, 30);
    let block = suite(&mut dice, Die::Block, 30);

    assert_ne!(d6, block);
}

// ---------------------------------------------------------------------------
// A3 — la réserve se prolonge sans rupture
// ---------------------------------------------------------------------------

/// Un pré-tirage court prolongé donne **exactement** ce qu'un pré-tirage long
/// aurait donné. La carte l'annonce comme une propriété de construction ; une
/// propriété évidente que rien ne tient se perd au premier remaniement.
#[test]
fn la_reserve_se_prolonge_comme_un_pre_tirage_plus_large() {
    let mut courte = Reserve::seeded(6, 1, GRAINE, 5);
    let mut longue = Reserve::seeded(6, 1, GRAINE, 40);

    let a: Vec<u8> = (0..40).map(|_| courte.next()).collect();
    let b: Vec<u8> = (0..40).map(|_| longue.next()).collect();

    assert_eq!(a, b, "prolonger diffère de pré-tirer davantage");
}

/// Deux flux distincts de la même clé ne se ressemblent pas. C'est ce que la
/// conception délègue à ChaCha plutôt qu'à une fonction de dérivation maison.
#[test]
fn deux_flux_de_la_meme_graine_different() {
    let mut zero = Reserve::seeded(6, 0, GRAINE, 20);
    let mut un = Reserve::seeded(6, 1, GRAINE, 20);

    let a: Vec<u8> = (0..20).map(|_| zero.next()).collect();
    let b: Vec<u8> = (0..20).map(|_| un.next()).collect();

    assert_ne!(a, b);
}

// ---------------------------------------------------------------------------
// A4 — une réserve écrite à la main
// ---------------------------------------------------------------------------

/// Ce qui rendra les tests de règles lisibles : « donne-moi deux crânes » plutôt
/// que « cherche une graine dont les deux premiers dés de blocage valent 1 ».
#[test]
fn une_reserve_ecrite_a_la_main_rend_ses_valeurs() {
    let mut dice = Dice::scripted(&[(Die::D6, &[1, 1, 6, 6]), (Die::Block, &[1, 1])]);

    assert_eq!(suite(&mut dice, Die::D6, 4), vec![1, 1, 6, 6]);
    assert_eq!(suite(&mut dice, Die::Block, 2), vec![1, 1]);
}

/// Épuisée, elle panique au lieu de rendre un dé venu d'ailleurs : le test a
/// consommé plus de dés qu'il n'en a déclaré, et il vaut mieux qu'il l'apprenne.
///
/// `expected` n'est pas du zèle. Un `#[should_panic]` nu est satisfait par
/// n'importe quelle panique — y compris celle du `todo!()` d'une implémentation
/// absente. Il passait donc au vert en phase 4, sans rien vérifier, et c'est le
/// seul test du lot qui ait échappé au filet.
#[test]
#[should_panic(expected = "plus de dés qu'il n'en a déclaré")]
fn une_reserve_ecrite_a_la_main_epuisee_panique() {
    let mut dice = Dice::scripted(&[(Die::D6, &[4])]);

    dice.roll(Die::D6);
    dice.roll(Die::D6);
}

/// Tirer un type qu'on n'a pas scripté est la même faute, et elle se voit moins
/// bien : le test croyait n'avoir besoin que de d6.
#[test]
#[should_panic(expected = "plus de dés qu'il n'en a déclaré")]
fn un_type_absent_du_script_panique() {
    let mut dice = Dice::scripted(&[(Die::D6, &[4])]);

    dice.roll(Die::D8);
}

// ---------------------------------------------------------------------------
// La conversion d'un tirage brut en face
// ---------------------------------------------------------------------------

/// La branche de rejet, qu'un vrai générateur atteindrait une fois sur un
/// milliard. C'est pour la couvrir que `face_from` est une fonction pure.
#[test]
fn le_haut_de_l_intervalle_est_rejete() {
    // 2³² mod 6 = 4 : les quatre derniers tirages bruts sont rejetés.
    assert_eq!(face_from(u32::MAX, 6), None);
    assert_eq!(face_from(u32::MAX - 3, 6), None);
    assert_eq!(face_from(u32::MAX - 4, 6), Some(6));
}

/// Un tirage rejeté est recommencé, et le suivant est pris. Ce test existe pour
/// une raison mécanique : à travers un vrai générateur, ce retour de boucle
/// n'arriverait qu'une fois sur un milliard, et la ligne resterait à jamais non
/// couverte. C'est `make check-arch` qui l'a réclamé.
#[test]
fn un_tirage_rejete_est_recommence() {
    let mut bruts = [u32::MAX, 7].into_iter();

    assert_eq!(draw_with(|| bruts.next().unwrap(), 6), 2);
}

/// Une source qui rejette toujours ne fait pas tourner le noyau à l'infini :
/// elle le fait s'arrêter. Couvre la borne posée sur la boucle de rejet.
#[test]
#[should_panic(expected = "la source n'est pas uniforme")]
fn une_source_qui_rejette_toujours_finit_par_alerter() {
    draw_with(|| u32::MAX, 6);
}

/// Le d8 et le d16 divisent 2³² : rien n'y est jamais rejeté.
#[test]
fn les_puissances_de_deux_ne_rejettent_rien() {
    assert!(face_from(u32::MAX, 8).is_some());
    assert!(face_from(u32::MAX, 16).is_some());
}

/// Les faces vont de 1 à `faces`, et toutes sortent.
#[test]
fn les_faces_commencent_a_un_et_les_couvrent_toutes() {
    let vues: Vec<u8> = (0..12u32).filter_map(|raw| face_from(raw, 6)).collect();

    assert_eq!(vues, vec![1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6]);
}

// ---------------------------------------------------------------------------
// La clé
// ---------------------------------------------------------------------------

/// La graine occupe les huit premiers octets, le reste est nul. Ce test fige la
/// construction : la changer changerait toutes les parties enregistrées, et
/// c'est le genre de modification qu'on veut voir rougir.
#[test]
fn la_cle_porte_la_graine_dans_ses_huit_premiers_octets() {
    let cle = key_from(0x0102_0304_0506_0708);

    assert_eq!(&cle[..8], &0x0102_0304_0506_0708u64.to_le_bytes());
    assert!(cle[8..].iter().all(|&o| o == 0));
}
