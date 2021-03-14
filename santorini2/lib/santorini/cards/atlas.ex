defmodule Santorini.Cards.Atlas do
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
      [:cap_build, player_id, worker_id, dR, dC] ->
        fn board ->
          {row, col} = Board.get_worker_position(board, player_id, worker_id)
          Board.update_space(board, row + dR, col + dC, fn _ -> 4 end)
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
        {:required, &Cards.Generic.get_available_move_options/4},
        {:required, &get_available_build_options/4}
      ],
      &Cards.Generic.would_win?/2,
      &to_function/1
    )
  end

  def get_available_build_options(board, player_id, worker_id, prev_actions) do
    {row, col} = Board.get_worker_position(board, player_id, worker_id)

    cap_build_options =
      BoardUtils.get_available_build_offsets(board, row, col)
      |> Enum.filter(fn {dR, dC} -> Board.space_height(board, row + dR, col + dC) < 3 end)
      |> Enum.map(fn {dR, dC} ->
        [:cap_build, player_id, worker_id, dR, dC]
      end)

    cap_build_options ++
      Cards.Generic.get_available_build_options(board, player_id, worker_id, prev_actions)
  end
end
