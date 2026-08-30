//! Ce qui circule entre un match et ceux qui le commandent.
//!
//! Une **commande** est une intention : elle peut être refusée. Un **événement**
//! est un fait : il s'est produit. Les deux ne se confondent pas, et c'est ce
//! qui permet à l'écran d'animer un récit — « esquive tentée, dé jeté, joueur
//! tombé, revirement » — plutôt que de recevoir « voici le nouveau monde ».
//!
//! Le module s'appelle `game` et non `match` : ce dernier est un mot réservé de
//! Rust, et `r#match` alourdirait chaque site d'appel pour rien.
//!
//! **Cette carte ne contient aucune règle de jeu.** Elle fixe le vocabulaire, et
//! une seule commande le traverse pour prouver que la chaîne tient.

use crate::dice::Dice;

/// Les deux camps. Le tour appartient à l'un d'eux à la fois.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Team {
    Blue,
    Red,
}

impl Team {
    /// L'autre camp. Utile partout où une règle rend la main.
    pub fn other(self) -> Team {
        match self {
            Team::Blue => Team::Red,
            Team::Red => Team::Blue,
        }
    }
}

/// Une intention soumise au match.
///
/// Elle ne porte pas son émetteur : celui-ci est passé à `submit`, parce qu'il
/// est **affirmé par le transport et non par le message**. Le jour où une
/// autorité serveur recevra ces commandes par le réseau, un client pourra
/// mentir sur ce qu'il veut faire, jamais sur qui il est.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Command {
    /// La seule vraie commande de cette carte. La carte 18 lui donnera son sens.
    EndTurn,

    /// Ouvre une question à l'entraîneur adverse.
    ///
    /// **Échafaudage, à supprimer par la carte 16.** Aucune règle ne produit
    /// encore de question ; sans une paire fabriquée, le mécanisme d'attente ne
    /// serait exercé par rien et n'existerait que sur le papier.
    ///
    /// Elle interroge délibérément l'**adversaire** et non l'entraîneur actif :
    /// une implémentation qui déduirait le propriétaire d'une décision du tour
    /// courant passerait tous les tests si la question revenait à l'actif. Or
    /// c'est précisément ce qu'il ne faut pas faire (cf. `Pending`).
    Ask,

    /// Réponse à la question en attente. Échafaudage, comme `Ask`.
    Answer(bool),
}

/// Un fait, déjà produit. Ordonnés, ils forment le récit du match.
///
/// **Contrainte enregistrée pour la carte 16**, tirée de la compétence `PRO`
/// (*« il peut tenter de relancer un seul dé […] dans le cadre d'un jet de dés
/// multiples »*) : le jour où un événement portera un jet, il devra identifier
/// **chaque dé séparément**. On ne peut pas désigner « le deuxième des trois »
/// si les dés sortent en bloc.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Event {
    TurnEnded { team: Team, turn: u32 },
    /// Échafaudage, comme `Command::Ask`.
    Answered { coach: Team, yes: bool },
}

/// Pourquoi une commande a été refusée.
///
/// Un refus n'est pas un événement : rien ne s'est produit. C'est ce qui
/// distingue les deux types que le document d'architecture décrit.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Rejected {
    /// Soumise par un entraîneur dont ce n'est pas le tour de parler.
    WrongCoach,
    /// Soumise par le bon entraîneur, mais elle n'est pas jouable ici.
    NotLegal,
}

/// Ce que le noyau attend, quand il s'est interrompu.
///
/// **`coach` n'est jamais déduit du tour courant.** À Blood Bowl, la case où un
/// joueur est repoussé est choisie par l'entraîneur adverse — et la compétence
/// `SIDESTEP` rend ce choix au poussé, tandis que `TAUNT` donne à l'entraîneur
/// du poussé le choix de faire suivre l'attaquant. La propriété d'une décision
/// se déplace ; la déduire serait faux la moitié du temps.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Pending {
    pub coach: Team,
    pub question: Question,
}

/// Ce qui est demandé.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Question {
    /// **Échafaudage, à supprimer par la carte 16.** Voir `Command::Answer`.
    Confirm,
}

/// Un match : son état, ses dés, et ce qu'il attend éventuellement.
///
/// **Pas `Clone`**, parce que `Dice` ne l'est pas (carte 13). C'est délibéré :
/// un déroulé du stratège qui clonerait l'état en emporterait les dés, et
/// verrait donc les tirages qui vont réellement sortir. Une copie doit dire
/// laquelle elle est — d'où `fork_for_rollout`, seul chemin vers un état de
/// simulation.
pub struct Match {
    dice: Dice,
    turn: u32,
    active: Team,
    pending: Option<Pending>,
}

impl Match {
    /// Un match neuf, dés compris.
    pub fn new(seed: u64) -> Self {
        Self {
            dice: Dice::new(seed),
            turn: 0,
            active: Team::Blue,
            pending: None,
        }
    }

    /// Un état pour dérouler un tour qui n'aura pas lieu.
    ///
    /// Copie tout **sauf les dés**, refaits depuis `rollout_seed`. C'est la
    /// seule manière d'obtenir une copie, et c'est ce qui empêche un déroulé de
    /// connaître l'avenir du vrai match.
    pub fn fork_for_rollout(&self, rollout_seed: u64) -> Self {
        Self {
            dice: Dice::new(rollout_seed),
            turn: self.turn,
            active: self.active,
            pending: self.pending,
        }
    }

    /// L'entraîneur dont c'est le tour de parler : celui qu'on attend s'il y a
    /// une question, sinon celui dont c'est le tour.
    pub fn to_act(&self) -> Team {
        match self.pending {
            Some(pending) => pending.coach,
            None => self.active,
        }
    }

    /// Ce que `to_act()` peut soumettre maintenant.
    ///
    /// En attente d'une réponse, cette liste ne contient **que** les réponses
    /// possibles : aucune commande ordinaire ne passe tant que la question n'a
    /// pas été tranchée.
    ///
    /// Rend un `Vec` pour l'instant. L'IA aura besoin d'un masque sur la carte
    /// d'actions plutôt que d'une liste — elle l'appellera 1 600 fois par match,
    /// sur 768 parties de front — mais la carte d'actions n'existe pas encore et
    /// une allocation par décision n'est pas mesurable ici.
    pub fn legal_commands(&self) -> Vec<Command> {
        match self.pending {
            Some(_) => vec![Command::Answer(true), Command::Answer(false)],
            None => vec![Command::EndTurn, Command::Ask],
        }
    }

    /// Soumet une intention. Rend les faits qu'elle a produits, ou son refus.
    ///
    /// **Un refus ne mute rien.** L'état après un refus est identique à l'état
    /// d'avant : sans quoi un journal rejoué divergerait sur une commande
    /// illégale, et le rejeu exact ne vaudrait plus rien.
    pub fn submit(&mut self, by: Team, command: Command) -> Result<Vec<Event>, Rejected> {
        if by != self.to_act() {
            return Err(Rejected::WrongCoach);
        }
        if !self.legal_commands().contains(&command) {
            return Err(Rejected::NotLegal);
        }
        Ok(self.apply(by, command))
    }

    /// Ce qui est attendu, s'il y a lieu.
    pub fn pending(&self) -> Option<Pending> {
        self.pending
    }

    /// Le numéro de tour. Un simple compteur tant que la carte 18 n'en a pas
    /// fait une structure.
    pub fn turn(&self) -> u32 {
        self.turn
    }
}

impl Match {
    /// La mutation, une fois la commande admise. Séparée de `submit` pour que
    /// la légalité se lise d'un bloc, sans le bruit de ce qu'elle autorise.
    fn apply(&mut self, by: Team, command: Command) -> Vec<Event> {
        match command {
            Command::EndTurn => {
                let ended = Event::TurnEnded {
                    team: self.active,
                    turn: self.turn,
                };
                self.active = self.active.other();
                self.turn += 1;
                vec![ended]
            }
            Command::Ask => {
                self.pending = Some(Pending {
                    coach: by.other(),
                    question: Question::Confirm,
                });
                Vec::new()
            }
            Command::Answer(yes) => {
                self.pending = None;
                vec![Event::Answered { coach: by, yes }]
            }
        }
    }
}

#[cfg(test)]
mod tests;
