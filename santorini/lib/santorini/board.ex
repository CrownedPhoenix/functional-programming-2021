defmodule Santorini.Board do
  @derive Jason.Encoder
  defstruct [:players, :spaces, :turn]
  @type t :: %__MODULE__{players: [[[0..4]]], spaces: [[1..4]], turn: integer}

  @spec update_players(board :: Board.t(), players :: [[[0..4]]]) :: Board.t()
  def update_players(board, players) do
    %Santorini.Board{players: players, spaces: board.spaces, turn: board.turn}
  end

  @spec update_worker(
          board :: Board.t(),
          player_id :: Int,
          worker_id :: Int,
          fun :: (row :: Int, col :: Int -> [0..4])
        ) :: Board.t()
  def update_worker(board, player_id, worker_id, fun) do
    update_players(
      board,
      List.update_at(board.players, player_id, fn player ->
        List.update_at(player, worker_id, fn worker ->
          fun.(Enum.at(worker, 0), Enum.at(worker, 1))
        end)
      end)
    )
  end

  @spec get_worker_position(board :: Board, player_id :: Int, worker_id :: Int) ::
          {Int, Int}
  def get_worker_position(board, player_id, worker_id) do
    Enum.at(board.players, player_id)
    |> Enum.at(worker_id)
    |> List.to_tuple()
  end

  @spec update_spaces(board :: Board.t(), spaces :: [[1..4]]) :: Board.t()
  def update_spaces(board, spaces) do
    %Santorini.Board{players: board.players, spaces: spaces, turn: board.turn}
  end

  @spec update_space(board :: Board.t(), row :: Int, col :: Int, fun :: (val :: Int -> Int)) ::
          Board.t()
  def update_space(board, row, col, fun) do
    update_spaces(
      board,
      List.update_at(board.spaces, row, fn r ->
        List.update_at(r, col, fun)
      end)
    )
  end

  @spec move_worker(board :: Board.t(), player_id :: Int, worker_id :: Int, dir :: Int) ::
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
end
