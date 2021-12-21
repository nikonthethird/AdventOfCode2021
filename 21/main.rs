#![feature(derive_default_enum)]
use std::collections::HashMap;

#[derive(Clone, Default, PartialEq, Eq, Hash)]
enum NextPlayer {
    #[default]
    Player1,
    Player2,
}

#[derive(Clone, Default, PartialEq, Eq, Hash)]
struct PlayerState {
    pub position: u8,
    pub score: u16,
}

#[derive(Clone, Default, PartialEq, Eq, Hash)]
struct UniverseState {
    pub next_player: NextPlayer,
    pub player1: PlayerState,
    pub player2: PlayerState,
}

#[derive(Default)]
struct MultiverseState {
    pub universes: HashMap<UniverseState, u64>,
    pub player1_wins: u64,
    pub player2_wins: u64,
}

const DICE_ROLLS: &[(u8, u64)] = &[(3, 1), (4, 3), (5, 6), (6, 7), (7, 6), (8, 3), (9, 1)];

fn perform_next_player_action<'state>(
    player_state: &'state PlayerState,
) -> impl Iterator<Item = (PlayerState, u64)> + 'state {
    DICE_ROLLS
        .iter()
        .map(|(dice_roll_points, dice_roll_universes)| {
            (
                PlayerState {
                    position: (player_state.position + dice_roll_points) % 10,
                    score: player_state.score
                        + ((player_state.position + dice_roll_points) % 10) as u16
                        + 1,
                },
                *dice_roll_universes,
            )
        })
}

fn perform_next_universe_action<'state>(
    universe_state: &'state UniverseState,
) -> impl Iterator<Item = (UniverseState, u64)> + 'state {
    perform_next_player_action(match universe_state.next_player {
        NextPlayer::Player1 => &universe_state.player1,
        NextPlayer::Player2 => &universe_state.player2,
    })
    .map(|(player_state, dice_roll_universes)| {
        (
            match universe_state.next_player {
                NextPlayer::Player1 => UniverseState {
                    next_player: NextPlayer::Player2,
                    player1: player_state,
                    player2: universe_state.player2.clone(),
                },
                NextPlayer::Player2 => UniverseState {
                    next_player: NextPlayer::Player1,
                    player1: universe_state.player1.clone(),
                    player2: player_state,
                },
            },
            dice_roll_universes,
        )
    })
}

fn perform_all_universe_actions<'state>(
    universes: &'state HashMap<UniverseState, u64>,
) -> impl Iterator<Item = (UniverseState, u64)> + 'state {
    universes
        .iter()
        .flat_map(|(universe_state, universe_count)| {
            perform_next_universe_action(universe_state).map(
                |(new_universe_state, dice_roll_universes)| {
                    (new_universe_state, *universe_count * dice_roll_universes)
                },
            )
        })
}

fn perform_next_multiverse_action(multiverse_state: MultiverseState) -> MultiverseState {
    perform_all_universe_actions(&multiverse_state.universes).fold(
        MultiverseState {
            universes: HashMap::new(),
            ..multiverse_state
        },
        |mut new_multiverse_state, (universe_state, universe_count)| {
            if universe_state.player1.score >= 21 {
                new_multiverse_state.player1_wins += universe_count;
            } else if universe_state.player2.score >= 21 {
                new_multiverse_state.player2_wins += universe_count;
            } else {
                *new_multiverse_state
                    .universes
                    .entry(universe_state)
                    .or_default() += universe_count;
            }
            new_multiverse_state
        },
    )
}

fn main() {
    let mut universe_state = UniverseState::default();
    universe_state.player1.position = 2 - 1;
    universe_state.player2.position = 5 - 1;
    let initial_universe_state = universe_state.clone();

    for dice in 0u16..500 {
        let player = if dice % 2 == 0 {
            &mut universe_state.player1
        } else {
            &mut universe_state.player2
        };
        player.position = (player.position + ((dice * 9 + 6) % 100) as u8) % 10;
        player.score += player.position as u16 + 1;
        if player.score >= 1000 {
            println!(
                "2021-12-21 Part 1: {}",
                (dice as u32 + 1)
                    * 3
                    * universe_state
                        .player1
                        .score
                        .min(universe_state.player2.score) as u32
            );
            break;
        }
    }

    let mut multiverse_state = MultiverseState::default();
    multiverse_state.universes.insert(initial_universe_state, 1);
    while multiverse_state.universes.len() > 0 {
        multiverse_state = perform_next_multiverse_action(multiverse_state);
    }
    println!(
        "2021-12-21 Part 2: {}",
        multiverse_state
            .player1_wins
            .max(multiverse_state.player2_wins)
    )
}
