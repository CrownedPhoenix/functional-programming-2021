defmodule Santorini.Cards.Apollo do
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
      [:swap, pId1, wId1, pId2, wId2] ->
        fn board -> swap_player_tokens(board, pId1, wId1, pId2, wId2) end

      generic ->
        Cards.Generic.to_function(action)
    end
  end

  @spec get_action_options(board :: Board.t(), player_id :: Int, worker_id :: Int) ::
          (Board.t() -> {Board.t(), Boolean})
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

    swap_moves = get_swap_moves(board, player_id, worker_id)
    regular_moves ++ swap_moves
  end

  def get_swap_moves(board, player_id, worker_id) do
    {row, col} = Board.get_worker_position(board, player_id, worker_id)
    opponent_id = Board.get_opponent_id(board, player_id)
    surrounding_spaces = BoardUtils.get_surrounding_spaces(board, row, col)

    Board.get_opponent_tokens(board, player_id)
    |> Stream.with_index()
    |> Stream.filter(fn {[oR, oC], _oWorker_id} ->
      {oR, oC} in surrounding_spaces and
        Board.can_move_between(board, row, col, oR, oC)
    end)
    |> Stream.map(fn {_, oWorker_id} ->
      [:swap, player_id, worker_id, opponent_id, oWorker_id]
    end)
    |> Enum.to_list()
  end

  def swap_player_tokens(board, pId1, wId1, pId2, wId2) do
    {w1R, w1C} = Board.get_worker_position(board, pId1, wId1)
    {w2R, w2C} = Board.get_worker_position(board, pId2, wId2)

    Board.update_player_token(board, pId1, wId1, fn _ -> [w2R, w2C] end)
    |> Board.update_player_token(pId2, wId2, fn _ -> [w1R, w1C] end)
  end
end
