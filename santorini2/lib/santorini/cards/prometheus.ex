defmodule Santorini.Cards.Prometheus do
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
        {:optional, &Cards.Generic.get_available_build_options/4},
        {:required, &get_available_move_options/4},
        {:required, &Cards.Generic.get_available_build_options/4}
      ],
      &Cards.Generic.would_win?/2,
      &Cards.Generic.to_function/1
    )
  end

  def get_available_move_options(board, player_id, worker_id, prev_actions) do
    case List.last(prev_actions) do
      [:build, _, _, _, _] ->
        {row, col} = Board.get_worker_position(board, player_id, worker_id)

        Cards.Generic.get_available_move_options(board, player_id, worker_id, prev_actions)
        |> Enum.filter(fn [:move, _, _, dR, dC] ->
          Board.space_height(board, row, col) >= Board.space_height(board, row + dR, col + dC)
        end)

      [:identity] ->
        Cards.Generic.get_available_move_options(board, player_id, worker_id, prev_actions)
    end
  end
end
