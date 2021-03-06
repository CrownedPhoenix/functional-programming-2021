defmodule Santorini.Board do
  @derive Jason.Encoder
  defstruct [:players, :spaces, :turn]

  @type t :: %__MODULE__{
          players: [%{card: String.t(), tokens: [[0..4]]}],
          spaces: [[1..4]],
          turn: Int
        }

  def new() do
    %Santorini.Board{
      players: [%{card: "", tokens: []}, %{card: "", tokens: []}],
      spaces: List.duplicate(List.duplicate(0, 5), 5),
      turn: 0
    }
  end

  @spec set_players(board :: Board.t(), players :: [%{card: String.t(), tokens: [[0..4]]}]) ::
          Board.t()
  def set_players(board, players) do
    %Santorini.Board{players: players, spaces: board.spaces, turn: board.turn}
  end

  @spec set_spaces(board :: Board.t(), spaces :: [[0..4]]) :: Board.t()
  def set_spaces(board, spaces) do
    %Santorini.Board{players: board.players, spaces: spaces, turn: board.turn}
  end

  @spec set_turn(board :: Board.t(), turn :: Int) :: Board.t()
  def set_turn(board, turn) do
    %Santorini.Board{players: board.players, spaces: board.spaces, turn: turn}
  end

  @spec set_player_card(board :: Board.t(), player_id :: Int, card :: String.t()) :: Board.t()
  def set_player_card(board, player_id, card) do
    set_players(
      board,
      List.update_at(board.players, player_id, fn %{card: _, tokens: tokens} ->
        %{card: card, tokens: tokens}
      end)
    )
  end

  @spec set_player_tokens(board :: Board.t(), player_id :: Int, tokens :: [[0..4]]) :: Board.t()
  def set_player_tokens(board, player_id, tokens) do
    set_players(
      board,
      List.update_at(board.players, player_id, fn %{card: card, tokens: _} ->
        %{card: card, tokens: tokens}
      end)
    )
  end

  def get_player_tokens(board, player_id) do
    Enum.at(board, player_id).tokens
  end

  def get_opponent_tokens(board, player_id) do
    opponent_id = get_opponent_id(board, player_id)
    Enum.at(board.players, opponent_id).tokens
  end

  def get_opponent_id(board, player_id) do
    rem(player_id + 1, 2)
  end

  @spec update_players(
          board :: Board.t(),
          fun ::
            ([%{card: String.t(), tokens: [[0..4]]}] -> [%{card: String.t(), tokens: [[0..4]]}])
        ) ::
          Board.t()
  def update_players(board, fun) do
    set_players(board, fun.(board.players))
  end

  @spec update_spaces(board :: Board.t(), fun :: ([[0..4]] -> [[0..4]])) :: Board.t()
  def update_spaces(board, fun) do
    set_spaces(board, fun.(board.spaces))
  end

  def update_space(board, row, col, fun) do
    update_spaces(board, fn spaces ->
      List.update_at(spaces, row, fn r ->
        List.update_at(r, col, fun)
      end)
    end)
  end

  @spec update_turn(board :: Board.t(), fun :: (Int -> Int)) :: Board.t()
  def update_turn(board, fun) do
    set_turn(board, fun.(board.turn))
  end

  @spec update_player_card(
          board :: Board.t(),
          player_id :: Int,
          fun :: (String.t() -> String.t())
        ) :: Board.t()
  def update_player_card(board, player_id, fun) do
    set_players(
      board,
      List.update_at(board.players, player_id, fn %{card: card, tokens: tokens} ->
        %{card: fun.(card), tokens: tokens}
      end)
    )
  end

  @spec update_player_tokens(board :: Board.t(), player_id :: Int, fun :: ([[0..4]] -> [[0..4]])) ::
          Board.t()
  def update_player_tokens(board, player_id, fun) do
    update_players(
      board,
      fn players ->
        List.update_at(players, player_id, fn %{card: card, tokens: tokens} ->
          %{card: card, tokens: fun.(tokens)}
        end)
      end
    )
  end

  @spec update_player_token(
          board :: Board.t(),
          player_id :: Int,
          token_id :: Int,
          fun :: ([0..4] -> [0..4])
        ) :: Board.t()
  def update_player_token(board, player_id, token_id, fun) do
    update_player_tokens(board, player_id, fn tokens ->
      List.update_at(tokens, token_id, fun)
    end)
  end

  @spec valid_space(board :: Board.t(), r :: Int, c :: Int) :: Boolean
  def valid_space(_board, r, c) do
    r in 0..4 and c in 0..4
  end

  @spec can_move_between(board :: Boart.t(), srcR :: Int, srcC :: Int, dstR :: Int, dstC :: Int) ::
          Boolean
  def can_move_between(board, srcR, srcC, dstR, dstC) do
    space_height(board, srcR, srcC) + 1 >=
      space_height(board, dstR, dstC)
  end

  def space_unoccupied(board, row, col) do
    [row, col] not in Enum.concat(
      Enum.at(board.players, 0).tokens,
      Enum.at(board.players, 1).tokens
    )
  end

  @spec space_height(board :: Board.t(), row :: Int, col :: Int) :: Int
  def space_height(board, row, col) do
    Enum.at(board.spaces, row) |> Enum.at(col)
  end

  @spec can_build_at(board :: Board.t(), row :: Int, col :: Int) :: Bool
  def can_build_at(board, row, col) do
    space_height(board, row, col) < 4
  end

  @spec get_worker_position(board :: Board, player_id :: Int, worker_id :: Int) ::
          {Int, Int}
  def get_worker_position(board, player_id, worker_id) do
    Enum.at(board.players, player_id).tokens
    |> Enum.at(worker_id)
    |> List.to_tuple()
  end

  @spec next_turn(board :: Board.t()) :: Board.t()
  def next_turn(board) do
    set_turn(board, board.turn + 1)
  end

  def swap_players(board) do
    update_players(board, &Enum.reverse/1)
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

      _ ->
        board
    end
  end

  @spec build(board :: Board.t(), player_id :: Int, worker_id :: Int, dR :: Int, dC :: Int) ::
          Board.t()
  def build(board, player_id, worker_id, dR, dC) do
    {row, col} = get_worker_position(board, player_id, worker_id)
    update_space(board, row + dR, col + dC, &(&1 + 1))
  end

  @spec move_worker(board :: Board.t(), player_id :: Int, worker_id :: Int, dir :: Int) ::
          Board.t()
  def move_worker(board, player_id, worker_id, dir) do
    case dir do
      # Move Up
      0 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row - 1, col] end)

      # Move Up-Right
      1 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row - 1, col + 1] end)

      # Move Right
      2 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row, col + 1] end)

      # Move Down-Right
      3 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row + 1, col + 1] end)

      # Move Down
      4 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row + 1, col] end)

      # Move Down-Left
      5 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row + 1, col - 1] end)

      # Move Left
      6 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row, col - 1] end)

      # Move Up-Left
      7 ->
        update_player_token(board, player_id, worker_id, fn row, col -> [row - 1, col - 1] end)

      _ ->
        board
    end
  end

  @spec move_worker(board :: Board.t(), player_id :: Int, worker_id :: Int, dR :: Int, dC :: Int) ::
          Board.t()
  def move_worker(board, player_id, worker_id, dR, dC) do
    {row, col} = get_worker_position(board, player_id, worker_id)
    update_player_token(board, player_id, worker_id, fn _ -> [row + dR, col + dC] end)
  end
end
