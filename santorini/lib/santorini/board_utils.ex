defmodule Santorini.BoardUtils do
  @moduledoc """
    Helpful functions for creating, drawing, and manipulating board state.
  """
  import Jason
  import Tuple
  alias Santorini.Board, as: Board

  @spec read_board_from!(file :: String.t()) :: Board.t()
  def read_board_from!(file) do
    struct(
      Board,
      File.read!(file)
      |> Jason.decode!()
      |> Map.to_list()
      |> Stream.map(fn
        {"players", value} ->
          {:players, restructure_players_list(value)}

        {"spaces", value} ->
          {:spaces, value}

        {"turn", value} ->
          {:turn, value}
      end)
    )
  end

  @spec draw(board :: Board.t()) :: Board.t()
  def draw(board) do
    Stream.with_index(board.spaces)
    |> Stream.each(fn {row, row_num} ->
      Stream.with_index(row)
      |> Stream.each(fn {val, col_num} ->
        cond do
          {row_num, col_num} in Enum.at(board.players, 0) ->
            IO.write(IO.ANSI.format([:blue_background, :white, "#{val}", :reset, " "]))

          {row_num, col_num} in Enum.at(board.players, 1) ->
            IO.write(IO.ANSI.format([:white_background, :black, "#{val}", :reset, " "]))

          true ->
            IO.write(IO.ANSI.format(["#{val} "]))
        end
      end)
      |> Stream.run()

      IO.write("\n")
    end)
    |> Stream.run()
  end

  def restructure_players_list(value) do
    value
    |> Stream.map(fn player ->
      Stream.map(player, fn locs ->
        Stream.map(locs, fn val -> val - 1 end) |> Enum.to_list() |> List.to_tuple()
      end)
      |> Enum.to_list()
    end)
    |> Enum.to_list()
  end
end
