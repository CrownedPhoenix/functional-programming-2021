defmodule Santorini.CLI do
  import OptionParser
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils

  def main(args \\ []) do
    {parsed, _, _} =
      parse(args,
        strict: [action: :integer, draw: :boolean, file: :string],
        aliases: [a: :action, d: :draw, f: :file]
      )

    # TODO: Implement the other flags

    players = Jason.decode!(IO.read(:stdio, :line))

    b =
      case length(players) do
        0 ->
          IO.puts(Jason.encode!([[3, 3], [1, 3]]))
          BoardUtils.from_json(IO.read(:stdio, :line))

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
      IO.puts(Jason.encode!(b))
      {b, BoardUtils.from_json(IO.read(:stdio, :line))}
    end)
    |> Stream.run()
  end

  def play() do
  end
end

# santorini < ./board.json
# santorini -a # < ./board.json
# santorini -d < ./board.json
# [[[3,3],[1,3]]]
