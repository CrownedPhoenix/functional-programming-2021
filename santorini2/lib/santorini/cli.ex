defmodule Santorini.CLI do
  use Bakeware.Script

  import OptionParser
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils

  @impl Bakeware.Script
  def main(args \\ []) do
    {parsed, _, _} =
      parse(args,
        strict: [
          action: :integer,
          draw: :boolean,
          swap_players: :boolean,
          gen: :boolean,
          turn: :boolean,
          options: :integer,
          state: :boolean
        ],
        aliases: [
          a: :action,
          d: :draw,
          s: :swap_players,
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

      [gen: true] ->
        BoardUtils.gen_random_starting_board("Artemis", "Apollo")
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
    players = IO.read(:stdio, :line) |> Jason.decode!([{:keys, :atoms}])

    b =
      case players do
        [%{card: c1}, %{card: c2}] ->
          [%{card: c2}, %{card: c1, tokens: [[3, 3], [1, 3]]}] |> Jason.encode!() |> IO.puts()

          IO.read(:stdio, :line) |> BoardUtils.from_json()

        [%{card: _}, %{card: _, tokens: _}] ->
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
