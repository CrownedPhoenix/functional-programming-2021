# Santorini

## Usage
`./santorini [-a | -d | -s | -v | -u | -g | -t | -o | --state]`
Options:  
- `--action # | -a #`: Performs the specified action on the input board (JSON). Output: JSON(Board)
- `--draw | -d`: Draws the input board (JSON) to the console.
- `--swap_players | -s`: Swaps the players list on the input board (JSON). Output: JSON(Board)
- `--vectorize | -v`: Converts the input board (JSON) into a vector (string of ASCII #s). Output: Vector(Board)
- `--unvectorize | -u`: Converts the input board (Vector) into a board (JSON). Output: JSON(Board)
- `--gen | -g`: Generates a random starting board. All spaces empty, but players have random positions. Output: JSON(Board)
- `--turn | -t`: Performs a random action on the input board and swaps the player list. Output: JSON(Board)
- `--options # | -o #`: Computes the possible valid actions for the specified player (0 or 1). Output: JSON(list)
- `--state`: Computes the victory state of the input board (JSON). Output: JSON({you: boolean, them: boolean})

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `santorini` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:santorini, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/santorini](https://hexdocs.pm/santorini).

