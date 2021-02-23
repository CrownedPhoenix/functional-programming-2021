defmodule Santorini.CLIFuncs do
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
      # TODO: Determine optimal actionId
      actionId = 0

      BoardUtils.action(b, actionId)
      |> BoardUtils.to_json()
      |> IO.puts()

      {b, BoardUtils.from_json(IO.read(:stdio, :line))}
    end)
    |> Stream.run()
  end
end
