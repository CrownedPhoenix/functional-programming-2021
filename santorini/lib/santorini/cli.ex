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
          gen: :boolean
        ],
        aliases: [
          a: :action,
          d: :draw,
          s: :swap_players,
          v: :vectorize,
          uv: :unvectorize,
          g: :boolean
        ]
      )

    case parsed do
      [action: actionId] ->
        b = BoardUtils.from_json(IO.read(:stdio, :line))
        <<playerId::1, workerId::1, moveDir::3, buildDir::3>> = <<actionId>>

        b
        |> Board.move_worker(playerId, workerId, moveDir)
        |> Board.build(playerId, workerId, buildDir)
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
        IO.read(:stdio, :line) |> BoardUtils.from_json() |> BoardUtils.unvectorize() |> IO.puts()

      [gen: true] ->
        BoardUtils.vectorize() |> IO.puts()

      _ ->
        play()
    end
  end

  def play() do
    players = IO.read(:stdio, :line) |> Jason.decode!()

    b =
      case length(players) do
        0 ->
          [[3, 3], [1, 3]] |> Jason.encode!() |> IO.puts()

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
      # TODO: Perform action
      BoardUtils.to_json(b)
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
