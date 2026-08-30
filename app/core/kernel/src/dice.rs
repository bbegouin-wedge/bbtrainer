//! Les dés du match : six suites tirées d'avance depuis une seule graine.
//!
//! Le noyau ne tire pas un dé quand il en a besoin — il déroule ses suites à la
//! construction et les consomme ensuite dans l'ordre. Consommer un dé, c'est
//! avancer un index.
//!
//! **Une réserve par type de dé.** Consommer un d8 ne décale donc aucun d6 :
//! ajouter demain une règle qui tire une direction ne change rien aux esquives
//! déjà enregistrées dans les journaux.
//!
//! **Une seule graine pour les six.** Elle est la clé ChaCha ; chaque type de dé
//! est un *flux* distinct de cette même clé. L'indépendance des six suites est
//! donc une propriété de l'algorithme, et non d'une fonction de dérivation qu'il
//! faudrait écrire, tester, et dont on douterait.
//!
//! Ce module ne connaît que des nombres. La table qui traduit un dé de blocage
//! en symbole — 1 Crâne, 2 Double chute… — est une règle du jeu : elle vit avec
//! le blocage, pas ici.

use rand_chacha::rand_core::{RngCore, SeedableRng};
use rand_chacha::ChaCha8Rng;

/// Les six types de dés de Blood Bowl.
///
/// Le dé de blocage en fait partie bien qu'il ait six faces comme le d6 : c'est
/// une réserve distincte, sans quoi chaque blocage décalerait la suite des
/// esquives et des jets d'armure.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Die {
    /// Distance de déviation quand le botteur a la compétence adéquate.
    D3,
    /// Le dé du jeu : esquive, course, ramassage, armure, blessure, distance de
    /// déviation.
    D6,
    /// Résultat d'un blocage. Six faces, traduites en symboles ailleurs.
    Block,
    /// Direction de déviation du ballon — les huit cases autour d'une case.
    D8,
    /// Sélection d'un joueur aligné au hasard : onze au plus sur le terrain.
    D12,
    /// Table des Prières à Nuffle.
    D16,
}

impl Die {
    /// Les six, dans l'ordre de leur emplacement.
    pub const ALL: [Die; 6] = [Die::D3, Die::D6, Die::Block, Die::D8, Die::D12, Die::D16];

    /// Numéro de flux ChaCha, et emplacement dans le tableau des réserves.
    ///
    /// **Ces numéros ne se renumérotent jamais.** Ils déterminent la suite de
    /// dés qu'une graine produit : échanger ceux du d8 et du d12 changerait
    /// toutes les parties déjà enregistrées, sans qu'aucune vérification ne le
    /// signale — les parties se rejoueraient, différemment.
    ///
    /// Écrits en clair plutôt que déduits de l'ordre des variantes, pour qu'un
    /// jour où l'on réordonne l'énumération ne change rien.
    ///
    /// Un septième type prendra le 6, et ne perturbera aucun des six premiers.
    fn stream(self) -> u64 {
        match self {
            Die::D3 => 0,
            Die::D6 => 1,
            Die::Block => 2,
            Die::D8 => 3,
            Die::D12 => 4,
            Die::D16 => 5,
        }
    }

    /// Le nombre de faces. Tous les dés du jeu sont uniformes sur les leurs.
    fn faces(self) -> u32 {
        match self {
            Die::D3 => 3,
            Die::D6 => 6,
            Die::Block => 6,
            Die::D8 => 8,
            Die::D12 => 12,
            Die::D16 => 16,
        }
    }

    /// Combien on en tire d'avance.
    ///
    /// Le d6 domine : ~1 100 dans un match ordinaire, jusqu'à 3 000 dans un
    /// match très violent. Les autres se comptent en dizaines. Ces nombres ne
    /// sont pas des limites — une réserve épuisée se prolonge — seulement le
    /// point où l'on cesse de tirer d'avance.
    fn prealloc(self) -> usize {
        match self {
            Die::D6 => 10_000,
            _ => 100,
        }
    }
}

/// Une suite de tirages uniformes sur `faces`, tirée d'avance et extensible.
///
/// `rng` n'est pas rembobiné après le pré-tirage : prolonger la suite, c'est
/// continuer le même flux. Le 10 001ᵉ tirage **est** donc celui qu'un
/// pré-tirage de 20 000 aurait donné — par construction, pas par arrangement.
struct Reserve {
    faces: u32,
    drawn: Vec<u8>,
    cursor: usize,
    /// Absent d'une réserve écrite à la main : celle-ci ne se prolonge pas, elle
    /// s'épuise bruyamment.
    rng: Option<ChaCha8Rng>,
}

impl Reserve {
    /// Une réserve tirée depuis la graine du match, sur un flux donné.
    ///
    /// `prealloc` est un paramètre plutôt que `die.prealloc()` : sans lui, aucun
    /// test ne pourrait comparer un pré-tirage court à un pré-tirage long, et
    /// l'équivalence des deux — la propriété que cette carte existe pour
    /// démontrer — resterait une affirmation. C'est le test qui l'a réclamé.
    ///
    /// Accessoirement, `Reserve` cesse ainsi de connaître `Die` : elle ne sait
    /// que compter des faces, ce qui est tout ce qu'on lui demande.
    fn seeded(faces: u32, stream: u64, seed: u64, prealloc: usize) -> Self {
        let mut rng = ChaCha8Rng::from_seed(key_from(seed));
        rng.set_stream(stream);
        let drawn = (0..prealloc)
            .map(|_| draw_with(|| rng.next_u32(), faces))
            .collect();
        Self {
            faces,
            drawn,
            cursor: 0,
            rng: Some(rng),
        }
    }

    /// Une réserve dont les valeurs sont données. Pour les tests de règles.
    fn scripted(faces: u32, values: &[u8]) -> Self {
        Self {
            faces,
            drawn: values.to_vec(),
            cursor: 0,
            rng: None,
        }
    }

    /// Le tirage suivant. Prolonge la suite si le curseur atteint le bout.
    ///
    /// Panique si une réserve écrite à la main est épuisée : le test a consommé
    /// plus de dés qu'il n'en a déclaré, et c'est une information utile.
    fn next(&mut self) -> u8 {
        if self.cursor == self.drawn.len() {
            let faces = self.faces;
            let rng = self.rng.as_mut().expect(
                "dés écrits à la main épuisés : le test a consommé \
                 plus de dés qu'il n'en a déclaré",
            );
            let v = draw_with(|| rng.next_u32(), faces);
            self.drawn.push(v);
        }
        let v = self.drawn[self.cursor];
        self.cursor += 1;
        v
    }
}

/// La clé ChaCha, construite depuis la graine du match.
///
/// À la main, et non par `seed_from_u64` : cette dernière étend le `u64` par
/// SplitMix64, une commodité de `rand_core` et non une partie de l'algorithme
/// ChaCha. En la contournant, un journal ne dépend plus que d'un algorithme
/// publié.
///
/// La clé est donc majoritairement nulle. Sans conséquence ici — on ne chiffre
/// rien — et vérifié : des graines voisines produisent des suites sans rapport.
fn key_from(seed: u64) -> [u8; 32] {
    let mut key = [0u8; 32];
    key[..8].copy_from_slice(&seed.to_le_bytes());
    key
}

/// La face correspondant à un tirage brut, ou `None` s'il faut le rejeter.
///
/// `raw % faces` suffirait presque. Sur les 2³² tirages bruts possibles, le
/// nombre de rejetés vaut `2³² mod faces` : 1 pour le d3, 4 pour le d6 et le
/// d12, et **zéro** pour le d8 et le d16, dont le nombre de faces divise 2³².
/// Le biais est donc d'environ un cas sur un milliard — et le rejet le supprime
/// pour trois lignes.
///
/// **Fonction pure, et c'est délibéré.** Le noyau doit être couvert à 100 %, et
/// la branche de rejet ne se produirait qu'une fois sur des centaines de
/// millions de tirages : elle serait incouvrable à travers un vrai générateur.
/// Isolée ici, elle se teste en l'appelant.
fn face_from(raw: u32, faces: u32) -> Option<u8> {
    let span = 1u64 << 32;
    let limite = span - span % faces as u64;
    if (raw as u64) < limite {
        Some((raw % faces) as u8 + 1)
    } else {
        None
    }
}

/// Un tirage, en rejetant le haut de l'intervalle jusqu'à en obtenir un bon.
///
/// **Paramétrée par la source des tirages bruts**, et non par le générateur.
/// C'est ce qui rend le retour de boucle atteignable par un test : à travers
/// ChaCha il ne se produirait qu'une fois sur un milliard, et jamais pour le d8
/// ni le d16.
///
/// La première version prenait le générateur directement, avec un commentaire
/// affirmant que la boucle n'ajoutait aucune ligne à couvrir. `make check-arch`
/// a répondu : 144 lignes sur 145, la manquante étant précisément le retour de
/// boucle. C'est la seconde fois dans ce module que l'exigence de couverture
/// impose de séparer une logique de sa source — la première étant `face_from`.
fn draw_with(mut raw: impl FnMut() -> u32, faces: u32) -> u8 {
    (0..TENTATIVES_MAX)
        .find_map(|_| face_from(raw(), faces))
        .expect("tirages bruts tous rejetés : la source n'est pas uniforme")
}

/// Combien de tirages bruts consécutifs on accepte de rejeter avant de conclure
/// que la source est cassée.
///
/// Une boucle non bornée serait plus simple, et c'est ce qu'il y avait ici.
/// `make check-mutations` a montré le prix : six mutations de `face_from` la
/// faisaient tourner à l'infini, chacune détectée en vingt secondes de délai
/// d'attente plutôt qu'en une milliseconde d'échec. La vérification passait de
/// deux secondes à deux minutes.
///
/// Mais le vrai motif n'est pas la vitesse des tests : une boucle de rejet non
/// bornée peut figer une partie pour toujours, et au milieu d'une nuit
/// d'auto-jeu, un plantage bruyant vaut mieux qu'un processus qui ne rend plus
/// la main.
///
/// 64 est absurdement généreux : un rejet arrive une fois sur un milliard, donc
/// soixante-quatre d'affilée n'arriveront jamais. C'est une alarme, pas un
/// réglage.
const TENTATIVES_MAX: usize = 64;

/// Les dés d'un match : six réserves, une par type.
///
/// **Volontairement non `Clone`.** C'est le garde-fou de la seule exigence que
/// l'infrastructure d'apprentissage impose à cette carte : quand le stratège
/// déroulera des tours qui n'ont pas lieu, il clonera l'état du match — et s'il
/// en clonait aussi les dés, ses simulations verraient **les dés qui vont
/// réellement sortir**. Il choisirait alors le plan qui gagne avec ceux-là,
/// c'est-à-dire qu'il jouerait en connaissant l'avenir. Rien ne le signalerait :
/// les tests passeraient, l'entraînement convergerait, l'agent gagnerait.
///
/// Sans `Clone`, aucun état de partie qui contient des dés ne peut être copié
/// par inadvertance. Toute copie devra dire explicitement quels dés elle prend.
pub struct Dice {
    reserves: [Reserve; 6],
}

impl Dice {
    /// Les six réserves d'un match, depuis sa graine.
    pub fn new(seed: u64) -> Self {
        Self {
            reserves: Die::ALL
                .map(|die| Reserve::seeded(die.faces(), die.stream(), seed, die.prealloc())),
        }
    }

    /// Des dés écrits à la main, pour les tests de règles : « donne-moi 1, 1,
    /// 6, 6 ». Un type absent de `scripts` n'a aucune valeur et paniquera si on
    /// le tire — ce qui dit au test ce qu'il a oublié de prévoir.
    pub fn scripted(scripts: &[(Die, &[u8])]) -> Self {
        Self {
            reserves: Die::ALL.map(|die| {
                let valeurs = scripts
                    .iter()
                    .find(|(d, _)| *d == die)
                    .map(|(_, v)| *v)
                    .unwrap_or(&[]);
                Reserve::scripted(die.faces(), valeurs)
            }),
        }
    }

    /// Le tirage suivant du type demandé, entre 1 et son nombre de faces.
    ///
    /// Point de passage unique : tous les dés du jeu sortent d'ici. C'est ce qui
    /// permettra d'y brancher le journal, un compteur ou une trace sans avoir à
    /// se souvenir de six endroits.
    pub fn roll(&mut self, die: Die) -> u8 {
        self.reserves[die.stream() as usize].next()
    }
}

#[cfg(test)]
mod tests;
