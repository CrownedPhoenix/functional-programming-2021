defmodule BoardUtils do
  @moduledoc """
  Documentation for BoardUtils.
  """

  @type board :: Board.board()

  @doc """
  Generates a random Sudoku Board.
  There are no guarantees on the solvability of the board.
  The actual fill % will be less than or equal to fill_pct.
  - m and n must be divisible by three.
  - fill_pct must be between 0-1
  """
  @spec gen_board(m :: non_neg_integer, n :: non_neg_integer, fill_pct :: float) :: board
  def gen_board(bm, bn, fill_pct) do
    b = Board.new(bm, bn)
    cell_positions = for r <- 0..(b.m - 1), c <- 0..(b.n - 1), do: {r, c}
    remaining = round(b.m * b.n * fill_pct)
    cell_positions = Enum.shuffle(cell_positions)
    gen_board_r(b, cell_positions, remaining)
  end

  def gen_board_r(board, cell_positions, remaining) do
    with _ when remaining != 0 <- remaining,
         [cell_position | rest] <- cell_positions,
         {r, c} <- cell_position,
         cell_possibilities <-
           get_cell_possibilities(board, r, c)
           |> Enum.shuffle(),
         [value | other_possibilities] <- cell_possibilities do
      newBoard = put_in(board[{r, c}], value)
      draw(newBoard)
      Process.sleep(100)
      gen_board_r(newBoard, rest, remaining - 1)
    else
      _ -> board
    end

    # if remaining == 0 or Enum.empty?(cell_positions) do
    #   board
    # else
    #   [cell_position | rest] = cell_positions
    #   {r, c} = cell_position

    #   cell_possibilities =
    #     get_cell_possibilities(board, r, c)
    #     |> Enum.shuffle()

    #   if Enum.empty?(cell_possibilities) do
    #     board
    #   else
    #     [value | other_possibilities] = cell_possibilities
    #     newBoard = put_in(board[{r, c}], value)
    #     draw(newBoard)
    #     Process.sleep(100)
    #     gen_board_r(newBoard, rest, remaining - 1)
    #   end
    # end
  end

  @doc """
  Generates an Sudoku board from a file.

  ## Examples

      iex> BoardUtils.gen_board_from_file("board.txt")
      %Board{ %{{0,1} => 0, {0,2} => 0, ...}, m: 3, n: 3}

  """
  @spec gen_board_from_file(String.t()) :: board
  def gen_board_from_file(filepath) do
    # Stream of nested lists of individual numbers from file
    lineTokens =
      File.stream!(filepath)
      |> Stream.map(&String.trim/1)
      |> Stream.map(&String.split(&1, "", trim: true))
      |> Stream.filter(&(!Enum.empty?(&1)))

    # Flatten the first line into m and n
    [bm, bn] =
      Stream.take(lineTokens, 1)
      |> Stream.flat_map(fn row ->
        Stream.filter(row, &(&1 != " "))
      end)
      |> Stream.map(&String.to_integer/1)
      |> Enum.to_list()

    # Flatten the remainder into a tuple-stream
    indexedTupleStream =
      Stream.drop(lineTokens, 1)
      |> Stream.with_index(0)
      |> Stream.flat_map(fn {row, rowIdx} ->
        Stream.filter(row, &(&1 != " "))
        |> Stream.with_index()
        |> Stream.map(fn
          {".", colIdx} ->
            {{rowIdx, colIdx}, 0}

          {strVal, colIdx} ->
            intVal = String.to_integer(strVal)
            {{rowIdx, colIdx}, intVal}
        end)
        |> Stream.filter(fn e -> elem(e, 1) != 0 end)
      end)

    # Tuple-stream to Map
    data = Map.new(indexedTupleStream)
    %Board{m: bm * 3, n: bn * 3, bm: bm, bn: bn, data: data}
  end

  @doc """
  Draws a Board to :stdio.

  """
  @spec draw(board :: Board) :: Board
  def draw(board) do
    IO.write(IO.ANSI.clear())

    for row <- 0..8, col <- 0..8 do
      case {row, col} do
        _ when col == 8 and row in [2, 5] ->
          if Board.has_value(board, row, col) do
            IO.write("#{board[{row, col}]}\n\n")
          else
            IO.write(".\n\n")
          end

        {_, 8} ->
          if Board.has_value(board, row, col) do
            IO.puts(board[{row, col}])
          else
            IO.puts(".")
          end

        _ when col in [2, 5] ->
          if Board.has_value(board, row, col) do
            IO.write("#{board[{row, col}]} ")
          else
            IO.write(". ")
          end

        _ ->
          if Board.has_value(board, row, col) do
            IO.write(board[{row, col}])
          else
            IO.write(".")
          end
      end
    end

    :ok
  end

  @doc """
  Returns a new Board in a solved state.

  """
  @spec solve(board :: Board) :: Board
  def solve(board) do
    [row, col] = [0, 0]
    draw(board)
    solve(board, row, col)
    :ok
  end

  @doc """
  Returns a new Board in a solved state.
  Only attempts solutions for positions at or after the specified row and column.

  """
  @spec solve(board :: Board, row :: non_neg_integer, col :: non_neg_integer) :: Board
  def solve(board, row, col) do
    cond do
      row == nil and col == nil ->
        board

      Board.has_value(board, row, col) ->
        {next_row, next_col} = get_next_row_col(board, row, col)
        solve(board, next_row, next_col)

      true ->
        {next_row, next_col} = get_next_row_col(board, row, col)
        cell_possibilities = get_cell_possibilities(board, row, col)

        Enum.find_value(cell_possibilities, fn value ->
          newBoard = put_in(board[{row, col}], value)
          draw(newBoard)
          Process.sleep(10)
          solve(newBoard, next_row, next_col)
        end)
    end
  end

  @doc """
  Returns the next {row, col} when traversed row-by-row, column-by-column.

  """
  @spec get_next_row_col(board :: Board, row :: non_neg_integer, col :: non_neg_integer) ::
          {non_neg_integer, non_neg_integer}
  def get_next_row_col(board, row, col) do
    %{m: m, n: n} = board
    next_position = row * n + col + 1
    next_row = div(next_position, n)
    next_col = rem(next_position, n)

    if next_row >= m do
      {nil, nil}
    else
      {next_row, next_col}
    end
  end

  @doc """
  Returns a list of possible values for the specified position on the board.
  """
  def get_cell_possibilities(board, row, col) do
    possible_row_values = get_possible_row_values(board, row) |> MapSet.new()
    possible_col_values = get_possible_col_values(board, col) |> MapSet.new()
    possible_block_values = get_possible_block_values(board, row, col) |> MapSet.new()
    intersection1 = MapSet.intersection(possible_row_values, possible_col_values)
    intersection2 = MapSet.intersection(intersection1, possible_block_values)
    MapSet.intersection(intersection1, intersection2) |> MapSet.to_list()
  end

  @doc """
  Returns a list of possible row values for the specified position on the board.
  """
  def get_possible_row_values(board, row) do
    %{m: _, n: n} = board
    all_row_possibilities = Enum.to_list(1..n)
    current_row_values = for r <- [row], c <- 0..n, do: board[{r, c}]
    all_row_possibilities -- current_row_values
  end

  @doc """
  Returns a list of possible column values for the specified position on the board.
  """
  def get_possible_col_values(board, col) do
    %{m: m, n: _} = board
    all_col_possibilities = Enum.to_list(1..m)
    current_col_values = for r <- 0..m, c <- [col], do: board[{r, c}]
    all_col_possibilities -- current_col_values
  end

  @doc """
  Returns a list of possible block values for the specified position on the board.
  """
  def get_possible_block_values(board, row, col) do
    %{bm: bm, bn: bn} = board
    block_row_start = div(row, bm) * bm
    block_col_start = div(col, bn) * bn
    all_block_possibilities = Enum.to_list(1..(bm * bn))

    current_block_values =
      for r <- block_row_start..(block_row_start + bm - 1),
          c <- block_col_start..(block_col_start + bn - 1) do
        board[{r, c}]
      end

    all_block_possibilities -- current_block_values
  end
end
