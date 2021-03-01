defmodule Santorini.CLI do
  import OptionParser
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
          gen: :boolean,
          turn: :boolean,
          options: :integer,
          state: :boolean
        ],
        aliases: [
          a: :action,
          d: :draw,
          s: :swap_players,
          v: :vectorize,
          u: :unvectorize,
          g: :gen,
          t: :turn,
          o: :options
        ]
      )

    Application.put_env(:elixir, :ansi_enabled, true)

    case parsed do
      [action: actionId] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
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

      [state: true] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
        |> BoardUtils.game_state()
        |> Jason.encode!()
        |> IO.puts()

      [turn: true] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
        |> BoardUtils.take_turn()
        |> Board.swap_players()
        |> BoardUtils.to_json()
        |> IO.puts()

      [options: playerId] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
        |> BoardUtils.get_action_options(playerId)
        |> Jason.encode!()
        |> IO.puts()

      _ ->
        play()
    end
  end

  def play() do
    players = IO.read(:stdio, :line) |> Jason.decode!()

    b =
      case length(players) do
        0 ->
          [[[3, 3], [1, 3]]] |> Jason.encode!() |> IO.puts()

          IO.read(:stdio, :line) |> BoardUtils.from_json()

        1 ->
          other = Enum.at(players, 0)

          mine =
            Stream.repeatedly(fn -> [:rand.uniform(5) - 1, :rand.uniform(5) - 1] end)
            |> Stream.filter(fn pos -> pos not in other end)
            |> Stream.take(2)
            |> Enum.to_list()

          Board.new() |> Board.update_players(players ++ [mine]) |> Board.update_turn(3)
      end

    Stream.unfold(b, fn b ->
      # TODO: Determine optimal actionId

      b
      |> BoardUtils.take_turn()
      |> BoardUtils.to_json()
      |> IO.puts()

      {b, BoardUtils.from_json(IO.read(:stdio, :line))}
    end)
    |> Stream.run()
  end
end

# santorini < ./board.json
# santorini -a # < ./board.json
# santorini -d < ./board.json
# [[[3,3],[1,3]]]
