defmodule Santorini.CLI do
  import OptionParser
  alias Santorini.Board, as: Board

  def main(args \\ []) do
    {parsed, _, _} =
      parse(args, strict: [action: :integer, draw: :boolean], aliases: [a: :action, d: :draw])

    # IO.read(:stdio, :line)
    # |> Jason.decode([{:keys, :atoms}])
    # |> (&struct(Board, &1))
  end
end

# santorini < ./board.json
# santorini -a # < ./board.json
# santorini -d < ./board.json
