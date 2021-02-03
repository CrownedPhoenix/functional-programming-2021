# SudokuElixir

## Summary
`board_utils.ex` contains utility methods for reading a board from a file and solving that board.
Currently, I just print to the console as the board is being solved. This is nice because if
I want to see it a little slower I can just add a Process.sleep(...) for however long I 
want it to pause between redraws. It's rather appealing to see it step through the
possibilities even though it takes a bruteforce approach.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sudoku_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sudoku_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/sudoku_elixir](https://hexdocs.pm/sudoku_elixir).

