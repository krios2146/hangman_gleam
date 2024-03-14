import gleam/string
import gleam/result
import gleam/io
import gleam/list
import gleam/erlang
import prng/random
import simplifile

const dictionary_file: String = "dictionary.txt"

pub fn main() {
  io.println("Welcome to the hagman game!")
  get_letter()
  |> io.println()
}

fn game_hub() {
  io.println("Do you want to play?")
  io.println("[Y]es / [N]o")
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

fn get_letter() -> String {
  erlang.get_line(prompt: "Enter a letter ")
  |> result.unwrap(or: "")
}
