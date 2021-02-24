defmodule Santorini.Board do
  @derive Jason.Encoder
  defstruct [:players, :spaces, :turn]
  @type t :: %__MODULE__{players: [[[0..4]]], spaces: [[1..4]], turn: integer}

  def new() do
    %Santorini.Board{players: [], spaces: List.duplicate(List.duplicate(0, 5), 5), turn: 0}
  end

  @spec update_players(board :: Board.t(), players :: [[[0..4]]]) :: Board.t()
  def update_players(board, players) do
    %Santorini.Board{players: players, spaces: board.spaces, turn: board.turn}
  end

  @spec update_spaces(board :: Board.t(), spaces :: [[1..4]]) :: Board.t()
  def update_spaces(board, spaces) do
    %Santorini.Board{players: board.players, spaces: spaces, turn: board.turn}
  end

  @spec update_turn(board :: Board.t(), turn :: Int) :: Board.t()
  def update_turn(board, turn) do
    %Santorini.Board{players: board.players, spaces: board.spaces, turn: turn}
  end

  @spec update_worker(
          board :: Board.t(),
          player_id :: Int,
          worker_id :: Int,
          fun :: (row :: Int, col :: Int -> [0..4])
        ) :: Board.t()
  def update_worker(board, player_id, worker_id, fun) do
    List.update_at(board.players, player_id, fn player ->
      List.update_at(player, worker_id, fn worker ->
        origin_r = Enum.at(worker, 0)
        origin_c = Enum.at(worker, 1)
        [new_r, new_c] = fun.(origin_r, origin_c)

        if valid_space(board, new_r, new_c) and space_unoccupied(board, new_r, new_c) and
             can_move_between(board, origin_r, origin_c, new_r, new_c) do
          [new_r, new_c]
        else
          [origin_r, origin_c]
        end
      end)
    end)
    |> (&update_players(board, &1)).()
  end

  @spec valid_space(board :: Board.t(), r :: Int, c :: Int) :: Boolean
  def valid_space(_board, r, c) do
    r in 0..4 and c in 0..4
  end

  @spec can_move_between(board :: Boart.t(), srcR :: Int, srcC :: Int, dstR :: Int, dstC :: Int) ::
          Boolean
  def can_move_between(board, srcR, srcC, dstR, dstC) do
    (board.spaces |> Enum.at(srcR) |> Enum.at(srcC)) + 1 >=
      board.spaces |> Enum.at(dstR) |> Enum.at(dstC)
  end

  @spec get_worker_position(board :: Board, player_id :: Int, worker_id :: Int) ::
          {Int, Int}
  def get_worker_position(board, player_id, worker_id) do
    Enum.at(board.players, player_id)
    |> Enum.at(worker_id)
    |> List.to_tuple()
  end

  @spec update_space(board :: Board.t(), row :: Int, col :: Int, fun :: (val :: Int -> Int)) ::
          Board.t()
  def update_space(board, row, col, fun) do
    with true <- row in 0..4,
         true <- col in 0..4,
         current_value <- Enum.at(board.spaces, row) |> Enum.at(col),
         true <- current_value < 4 do
      update_spaces(
        board,
        List.update_at(board.spaces, row, fn r ->
          List.update_at(r, col, fun)
        end)
      )
    else
      _ -> board
    end
  end

  def space_unoccupied(board, row, col) do
    [row, col] not in Enum.concat(board.players)
  end

  @spec build(board :: Board.t(), player_id :: Int, worker_id :: Int, dir :: Int) ::
          Board.t()
  def build(board, player_id, worker_id, dir) do
    {row, col} = get_worker_position(board, player_id, worker_id)

    case dir do
      # Build Up
      0 ->
        update_space(board, row - 1, col, &(&1 + 1))

      # Build Up-Right
      1 ->
        update_space(board, row - 1, col + 1, &(&1 + 1))

      # Build Right
      2 ->
        update_space(board, row, col + 1, &(&1 + 1))

      # Build Down-Right
      3 ->
        update_space(board, row + 1, col + 1, &(&1 + 1))

      # Build Down
      4 ->
        update_space(board, row + 1, col, &(&1 + 1))

      # Build Down-Left
      5 ->
        update_space(board, row + 1, col - 1, &(&1 + 1))

      # Build Left
      6 ->
        update_space(board, row, col - 1, &(&1 + 1))

      # Build Up-Left
      7 ->
        update_space(board, row - 1, col - 1, &(&1 + 1))
    end
  end

  @spec move_worker(board :: Board.t(), player_id :: Int, worker_id :: Int, dir :: Int) ::
          Board.t()
  def move_worker(board, player_id, worker_id, dir) do
    case dir do
      # Move Up
      0 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row - 1, col] end)

      # Move Up-Right
      1 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row - 1, col + 1] end)

      # Move Right
      2 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row, col + 1] end)

      # Move Down-Right
      3 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row + 1, col + 1] end)

      # Move Down
      4 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row + 1, col] end)

      # Move Down-Left
      5 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row + 1, col - 1] end)

      # Move Left
      6 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row, col - 1] end)

      # Move Up-Left
      7 ->
        update_worker(board, player_id, worker_id, fn row, col -> [row - 1, col - 1] end)
    end
  end

  @spec next_turn(board :: Board.t()) :: Board.t()
  def next_turn(board) do
    update_turn(board, board.turn + 1)
  end

  def swap_players(board) do
    %Santorini.Board{players: Enum.reverse(board.players), spaces: board.spaces, turn: board.turn}
  end
end
