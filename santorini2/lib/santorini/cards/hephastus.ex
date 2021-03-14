defmodule Santorini.Cards.Hephastus do
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
        {:required, &Cards.Generic.get_available_build_options/4},
        {:optional, &second_build_options/4}
      ],
      &Cards.Generic.would_win?/2,
      &Cards.Generic.to_function/1
    )
  end

  def second_build_options(board, player_id, worker_id, prev_actions) do
    [:build, _, _, dR, dC] = List.last(prev_actions)
    {row, col} = Board.get_worker_position(board, player_id, worker_id)

    Cards.Generic.get_available_build_options(board, player_id, worker_id, prev_actions)
    |> Enum.filter(fn [:build, _, _, pdR, pdC] ->
      (dR == pdR and dC == pdC) and Board.space_height(board, row + dR, col + dC) < 3
    end)
  end
end
