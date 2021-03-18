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
          state: :boolean,
          test: :boolean,
          strategy: :string
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
        |> BoardUtils.take_turn(:random)
        |> Board.swap_players()
        |> BoardUtils.to_json()
        |> IO.puts()

      [test: true, strategy: strat] ->
        IO.write("[{\"card\":\"Demeter\"},{\"card\":\"Minotaur\"}]\n")
        play(String.to_atom(strat))

      [test: true] ->
        IO.write("[{\"card\":\"Demeter\"},{\"card\":\"Minotaur\"}]\n")
        play(:random)

      [options: playerId] ->
        IO.read(:stdio, :line)
        |> BoardUtils.from_json()
        |> BoardUtils.get_action_options(playerId)
        |> Jason.encode!()
        |> IO.puts()

      [strategy: strat] ->
        play(String.to_atom(strat))

      _ ->
        play(:random)
    end
  end

  def play(strategy) do
    players = IO.read(:stdio, :line) |> Jason.decode!([{:keys, :atoms}])

    b =
      case players do
        [%{card: my_card}, %{card: c2, tokens: t2}] ->
          other = Enum.at(players, 1)

          my_tokens =
            Stream.repeatedly(fn -> [Enum.random(1..5), Enum.random(1..5)] end)
            |> Stream.filter(fn pos -> pos not in other end)
            |> Stream.uniq()
            |> Stream.take(2)
            |> Enum.to_list()

          [%{card: c2, tokens: t2}, %{card: my_card, tokens: my_tokens}]
          |> Jason.encode!()
          |> IO.puts()

          IO.read(:stdio, :line) |> BoardUtils.from_json()

        [%{card: c1}, %{card: c2}] ->
          starting_tokens =
            Stream.repeatedly(fn -> [Enum.random(1..5), Enum.random(1..5)] end)
            |> Stream.uniq()
            |> Stream.take(2)
            |> Enum.to_list()

          [%{card: c2}, %{card: c1, tokens: starting_tokens}] |> Jason.encode!() |> IO.puts()

          IO.read(:stdio, :line)
          |> BoardUtils.from_json()
      end

    Stream.unfold(b, fn b ->
      b
      |> BoardUtils.take_turn(strategy)
      # |> BoardUtils.draw(:stderr)
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
