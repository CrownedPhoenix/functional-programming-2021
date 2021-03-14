defmodule Santorini.Cards.Pan do
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils
  alias Santorini.Cards, as: Cards

  @spec get_action_options(board :: Board.t(), player_id :: Int, worker :: Int) ::
          (Board.t() -> Board.t())
  def get_action_options(board, player_id, worker_id) do
    Cards.Generic.bind(
      board,
      player_id,
      worker_id,
      [
        {:required, &Cards.Generic.get_available_move_options/4},
        {:required, &Cards.Generic.get_available_build_options/4}
      ],
      &would_win?/2,
      &Cards.Generic.to_function/1
    )
  end

  def would_win?(board, action) do
    case action do
      [:move, player_id, worker_id, dR, dC] ->
        {row, col} = Board.get_worker_position(board, player_id, worker_id)
        from_space_height = Board.space_height(board, row, col)
        to_space_height = Board.space_height(board, row + dR, col + dC)
       to_space_height == 3 or
         from_space_height >= to_space_height + 2

      _ ->
        false
    end
  end
end
