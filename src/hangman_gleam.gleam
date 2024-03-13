import gleam/string
import gleam/result
import gleam/io
import gleam/list
import prng/random
import simplifile

pub fn main() {
  let dictionary =
    simplifile.read("dictionary.txt")
    |> result.unwrap(or: "")

  let words = string.split(dictionary, on: "\n")

  let generator = random.int(0, list.length(of: words) - 1)
  let random_index = random.random_sample(generator)

  list.at(in: words, get: random_index)
  |> result.unwrap(or: "")
  |> string.append("random word from dictionary: ", _)
  |> io.println()
}
