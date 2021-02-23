defmodule Santorini.CLI do
  import OptionParser
  import Santorini.CLIFuncs
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils

  def main(args \\ []) do
    {parsed, _, _} =
      parse(args,
        strict: [
          action: :integer,
          draw: :boolean,
          swap_players: :boolean,
          vectorize: :boolean,
          unvectorize: :boolean,
          gen: :boolean
        ],
        aliases: [
          a: :action,
          d: :draw,
          s: :swap_players,
          v: :vectorize,
          u: :unvectorize,
          g: :gen
        ]
      )

    Application.put_env(:elixir, :ansi_enabled, true)

    case parsed do
      [action: actionId] ->
        b = BoardUtils.from_json(IO.read(:stdio, :line))

        b
        |> BoardUtils.action(actionId)
        |> BoardUtils.to_json()
        |> IO.puts()

      [swap_players: true] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
        |> Board.swap_players()
        |> BoardUtils.to_json()
        |> IO.puts()

      [draw: true] ->
        IO.read(:stdio, :line) |> BoardUtils.from_json() |> BoardUtils.draw()

      [vectorize: true] ->
        IO.read(:stdio, :line) |> BoardUtils.from_json() |> BoardUtils.vectorize() |> IO.puts()

      [unvectorize: true] ->
        IO.read(:stdio, :line)
        |> String.trim()
        |> BoardUtils.unvectorize()
        |> BoardUtils.to_json()
        |> IO.puts()

      [gen: true] ->
        BoardUtils.gen_random_starting_board()
        |> BoardUtils.to_json()
        |> IO.puts()

      _ ->
        play()
    end
  end
end

# santorini < ./board.json
# santorini -a # < ./board.json
# santorini -d < ./board.json
# [[[3,3],[1,3]]]
