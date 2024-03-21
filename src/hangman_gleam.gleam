import gleam/string
import gleam/bool
import gleam/result
import gleam/io
import gleam/int
import gleam/list
import gleam/erlang
import prng/random
import simplifile

const dictionary_file: String = "dictionary.txt"

const alphabet: List(String) = [
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
  "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]

const max_mistakes: Int = 6

type GameState {
  GameState(
    word: String,
    word_mask: String,
    used_letters: List(String),
    mistakes: Int,
    guessed_letter: String,
  )
}

pub fn main() {
  io.println("Welcome to the hagman game!")
  game_hub()
}

fn game_hub() {
  io.println("Do you want to play?")
  io.println("[Y]es / [N]o\n")

  case get_input(allowed_letters: ["y", "n"]) {
    "y" -> {
      let word = choose_word(get_dictionary())
      let word_mask = string.repeat("*", times: string.length(word))

      game_cycle(GameState(
        word,
        word_mask,
        used_letters: [],
        mistakes: 0,
        guessed_letter: "",
      ))
      game_hub()
    }
    _ -> {
      io.println("Exiting...")
      Nil
    }
  }
}

fn game_cycle(game_state: GameState) -> Nil {
  case is_game_continues(game_state) {
    True -> {
      display_hangman(game_state)
      |> display_mistakes()
      |> display_used_letters()
      |> display_word_mask()
      |> guess_letter()
      |> update_word_mask()
      |> update_mistakes()
      |> update_used_letters()
      |> game_cycle()
    }
    False -> {
      case is_game_lost(game_state) {
        True -> {
          display_game_over(game_state)
        }
        False -> {
          display_congrats(game_state)
        }
      }
    }
  }
}

fn is_game_continues(game_state: GameState) -> Bool {
  bool.negate(bool.or(is_game_lost(game_state), is_game_won(game_state)))
}

fn is_game_lost(game_state: GameState) -> Bool {
  game_state.mistakes >= max_mistakes
}

fn is_game_won(game_state: GameState) -> Bool {
  !string.contains(game_state.word_mask, "*")
}

fn display_game_over(game_state: GameState) -> Nil {
  display_hangman(game_state)
  io.println("Unfortunately, you lost")
  io.println("The word was: " <> game_state.word)
}

fn display_congrats(game_state: GameState) -> Nil {
  display_hangman(game_state)
  io.println("Congratulations, you won")
}

fn display_hangman(game_state: GameState) -> GameState {
  case game_state.mistakes {
    0 ->
      io.println(
        "
  +---+
  |   |
      |
      |
      |
      |
=========
",
      )

    1 ->
      io.println(
        "
  +---+
  |   |
  0   |
      |
      |
      |
=========",
      )
    2 ->
      io.println(
        "
  +---+
  |   |
  0   |
  |   |
      |
      |
=========",
      )
    3 ->
      io.println(
        "
  +---+
  |   |
  0   |
 /|   |
      |
      |
=========",
      )
    4 ->
      io.println(
        "
  +---+
  |   |
  0   |
 /|\\  |
      |
      |
=========",
      )
    5 ->
      io.println(
        "
  +---+
  |   |
  0   |
 /|\\  |
 /    |
      |
=========",
      )
    _ ->
      io.println(
        "
  +---+
  |   |
  0   |
 /|\\  |
 / \\  |
      |
=========",
      )
  }

  game_state
}

fn display_mistakes(game_state: GameState) -> GameState {
  io.println("Mistakes: " <> int.to_string(game_state.mistakes))

  game_state
}

fn display_used_letters(game_state: GameState) -> GameState {
  let used_letters =
    game_state.used_letters
    |> list.map(string.append(_, ", "))
    |> string.concat()
    |> string.drop_right(up_to: 2)

  let used_letters = case string.is_empty(used_letters) {
    True -> "none"
    False -> used_letters
  }

  io.println("Used letters: " <> used_letters)

  game_state
}

fn display_word_mask(game_state: GameState) -> GameState {
  io.println("Word to guess: " <> game_state.word_mask)

  game_state
}

fn guess_letter(game_state: GameState) -> GameState {
  let guessed_letter = get_input(alphabet)

  GameState(..game_state, guessed_letter: guessed_letter)
}

fn update_word_mask(game_state: GameState) -> GameState {
  let guess = game_state.guessed_letter
  let word = game_state.word

  let word_mask =
    find_all(word, guess, [], string.length(word) - 1)
    |> update_all(game_state.word_mask, guess, _, string.length(word) - 1)

  GameState(..game_state, word_mask: word_mask)
}

fn update_mistakes(game_state: GameState) -> GameState {
  let mistakes = game_state.mistakes
  let guessed_letter = game_state.guessed_letter
  let used_letters = game_state.used_letters
  let word = game_state.word

  let mistakes = case list.contains(used_letters, guessed_letter) {
    True -> mistakes
    False ->
      case string.contains(word, guessed_letter) {
        True -> mistakes
        False -> mistakes + 1
      }
  }

  GameState(..game_state, mistakes: mistakes)
}

fn update_used_letters(game_state: GameState) -> GameState {
  let used_letters = case
    list.contains(game_state.used_letters, game_state.guessed_letter)
  {
    True -> game_state.used_letters
    False -> [game_state.guessed_letter, ..game_state.used_letters]
  }

  GameState(..game_state, used_letters: used_letters)
}

fn update_all(
  word_mask: String,
  letter: String,
  indicies: List(Int),
  index: Int,
) -> String {
  case index {
    -1 -> word_mask
    _ -> {
      let word_mask = case list.contains(indicies, index) {
        True -> {
          let left = string.slice(word_mask, 0, index)
          let right =
            string.slice(word_mask, index + 1, string.length(word_mask) - 1)
          left <> letter <> right
        }
        False -> word_mask
      }
      update_all(word_mask, letter, indicies, index - 1)
    }
  }
}

fn find_all(
  word: String,
  letter: String,
  result: List(Int),
  index: Int,
) -> List(Int) {
  case index {
    -1 -> result
    _ -> {
      let word = string.to_graphemes(word)
      let result = case
        list.at(word, index)
        |> result.unwrap("")
        == letter
      {
        True -> {
          [index, ..result]
        }
        False -> {
          result
        }
      }
      find_all(string.concat(word), letter, result, index - 1)
    }
  }
}

fn choose_word(from words: List(String)) -> String {
  let generator = random.int(0, list.length(of: words) - 1)
  let random_index = random.random_sample(generator)

  list.at(in: words, get: random_index)
  |> result.unwrap(or: "random")
}

fn get_dictionary() -> List(String) {
  simplifile.read(dictionary_file)
  |> result.unwrap(or: "")
  |> string.split(on: "\n")
}

fn get_input(allowed_letters allowed_letters: List(String)) -> String {
  let input =
    erlang.get_line(prompt: "Enter a letter: ")
    |> result.unwrap(or: "")
    |> string.lowercase()
    |> string.first()
    |> result.unwrap(or: "")

  case list.contains(allowed_letters, input) {
    True -> input
    False -> {
      io.println("Please, enter one of the following:")
      io.debug(allowed_letters)

      get_input(allowed_letters)
    }
  }
}
