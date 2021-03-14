defmodule Santorini.Cards.Generic do
  alias Santorini.Board, as: Board
  alias Santorini.BoardUtils, as: BoardUtils

  @spec to_function(actions :: [[]]) :: Board.t()
  def to_function([actions | _]) when is_list(actions) do
    Enum.reduce(actions, &Function.identity/1, fn action, fun ->
      fn board -> fun.(board) |> to_function(action).() end
    end)
  end

  def to_function(action) when is_list(action) do
    case action do
      [:move, player_id, worker_id, dR, dC] ->
        fn board -> Board.move_worker(board, player_id, worker_id, dR, dC) end

      [:build, player_id, worker_id, dR, dC] ->
        fn board -> Board.build(board, player_id, worker_id, dR, dC) end

      [:identity] ->
        fn board -> board end
    end
  end

  def get_available_build_options(board, player_id, worker_id, _actions) do
    {row, col} = Board.get_worker_position(board, player_id, worker_id)

    BoardUtils.get_available_build_offsets(board, row, col)
    |> Enum.map(fn {dR, dC} ->
      [:build, player_id, worker_id, dR, dC]
    end)
  end

  def get_available_move_options(board, player_id, worker_id, _actions) do
    {row, col} = Board.get_worker_position(board, player_id, worker_id)

    BoardUtils.get_available_move_offsets(board, row, col)
    |> Enum.map(fn {dR, dC} ->
      [:move, player_id, worker_id, dR, dC]
    end)
  end

  def would_win?(board, action) do
    case action do
      [:move, player_id, worker_id, dR, dC] ->
        {row, col} = Board.get_worker_position(board, player_id, worker_id)
        Board.space_height(board, row + dR, col + dC) == 3

      _ ->
        false
    end
  end

  def bind(starting_board, player_id, worker_id, option_stages, would_win?, to_func) do
    root = [{false, starting_board, [[:identity]]}]

    Enum.reduce(option_stages, root, fn {stage_type, get_stage_options}, action_paths ->
      Enum.flat_map(action_paths, fn action_path ->
        case action_path do
          {true, _, _} ->
            [action_path]

          {false, board, actions} ->
            stage_options = get_stage_options.(board, player_id, worker_id, actions)

            new_action_paths =
              Enum.map(stage_options, fn option ->
                {would_win?.(board, option), board |> to_func.(option).(), actions ++ [option]}
              end)

            case stage_type do
              :optional ->
                new_action_paths ++ [action_path]

              :required ->
                new_action_paths
            end
        end
      end)
    end)
  end
end
