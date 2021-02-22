defmodule Santorini.BoardUtils do
  @moduledoc """
    Helpful functions for creating, drawing, and manipulating board state.
  """
  require Jason
  alias Santorini.Board, as: Board

  @spec from_json(json :: String.t()) :: Board.t()
  def from_json(json) do
    Jason.decode!(json, [{:keys, :atoms}])
    |> (&struct(Board, &1)).()
    |> fix_players_list()
  end

  def to_json(board) do
    board
    |> unfix_players_list()
    |> Jason.encode!()
  end

  @spec read_board_from!(file :: String.t()) :: Board.t()
  def read_board_from!(file) do
    File.read!(file)
    |> from_json()
  end

  @spec draw(board :: Board.t()) :: Board.t()
  def draw(board) do
    Stream.with_index(board.spaces)
    |> Stream.each(fn {row, row_num} ->
      Stream.with_index(row)
      |> Stream.each(fn {val, col_num} ->
        cond do
          [row_num, col_num] in Enum.at(board.players, 0) ->
            IO.write(IO.ANSI.format([:blue_background, :white, "#{val}", :reset, " "]))

          [row_num, col_num] in Enum.at(board.players, 1) ->
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

  @spec gen_random_starting_board() :: Board.t()
  def gen_random_starting_board() do
    random_players =
      Stream.transform(1..4, [], fn i, chosen ->
        choice =
          Stream.repeatedly(fn -> [Enum.random(0..4), Enum.random(0..4)] end)
          |> Stream.filter(fn pos -> pos not in chosen end)
          |> Stream.take(1)
          |> Enum.to_list()

        {choice, chosen ++ choice}
      end)
      |> Stream.chunk_every(2, 2)
      |> Enum.to_list()

    Board.new() |> Board.update_players(random_players)
  end

  def unfix_players_list(board) do
    Board.update_players(
      board,
      board.players
      |> Stream.map(fn player ->
        Stream.map(player, fn locs ->
          Stream.map(locs, fn val -> val + 1 end) |> Enum.to_list()
        end)
        |> Enum.to_list()
      end)
      |> Enum.to_list()
    )
  end

  def fix_players_list(board) do
    Board.update_players(
      board,
      board.players
      |> Stream.map(fn player ->
        Stream.map(player, fn locs ->
          Stream.map(locs, fn val -> val - 1 end) |> Enum.to_list()
        end)
        |> Enum.to_list()
      end)
      |> Enum.to_list()
    )
  end
end
