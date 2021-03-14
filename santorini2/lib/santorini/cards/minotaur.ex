defmodule Santorini.Cards.Minotaur do
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils
  alias Santorini.Cards, as: Cards

  @spec to_function(actions :: [[]]) :: Board.t()
  def to_function([actions | _]) when is_list(actions) do
    Enum.reduce(actions, &Function.identity/1, fn action, fun ->
      fn board -> fun.(board) |> to_function(action).() end
    end)
  end

  def to_function(action) when is_list(action) do
    case action do
      [:push_move, pId1, wId1, opId2, owId2, odR, odC] ->
        fn board ->
          {oR, oC} = Board.get_worker_position(board, opId2, owId2)

          Board.move_worker(board, opId2, owId2, odR, odC)
          |> Board.update_player_token(pId1, wId1, fn _ -> [oR, oC] end)
        end

      generic ->
        Cards.Generic.to_function(action)
    end
  end

  @spec get_action_options(board :: Board.t(), player_id :: Int, worker :: Int) ::
          (Board.t() -> Board.t())
  def get_action_options(board, player_id, worker_id) do
    Cards.Generic.bind(
      board,
      player_id,
      worker_id,
      [
        {:required, &move_options/4},
        {:required, &Cards.Generic.get_available_build_options/4}
      ],
      &Cards.Generic.would_win?/2,
      &to_function/1
    )
  end

  def move_options(board, player_id, worker_id, prev_actions) do
    regular_moves =
      Cards.Generic.get_available_move_options(board, player_id, worker_id, prev_actions)

    push_moves = get_push_moves(board, player_id, worker_id)
    regular_moves ++ push_moves
  end

  def get_push_moves(board, player_id, worker_id) do
    {row, col} = Board.get_worker_position(board, player_id, worker_id)
    opponent_id = Board.get_opponent_id(board, player_id)
    surrounding_spaces = BoardUtils.get_surrounding_spaces(board, row, col)

    Board.get_opponent_tokens(board, player_id)
    |> Stream.with_index()
    |> Stream.filter(fn {[oR, oC], _oWorker_id} ->
      {oR, oC} in surrounding_spaces and
        Board.can_move_between(board, row, col, oR, oC)
    end)
    |> Stream.flat_map(fn {[oR, oC], oWorker_id} ->
      board_delta = Board.update_player_token(board, player_id, worker_id, fn _ -> [oR, oC] end)

      BoardUtils.get_surrounding_offsets(board_delta, oR, oC)
      |> Stream.filter(fn {dR, dC} ->
        Board.space_height(board_delta, oR + dR, oC + dC) < 4 and
          Board.space_unoccupied(board_delta, oR + dR, oC + dC)
      end)
      |> Stream.map(fn {odR, odC} ->
        [:push_move, player_id, worker_id, opponent_id, oWorker_id, odR, odC]
      end)
      |> Enum.to_list()
    end)
    |> Enum.to_list()
  end
end
