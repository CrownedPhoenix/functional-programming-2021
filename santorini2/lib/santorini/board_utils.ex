defmodule Santorini.BoardUtils do
  @moduledoc """
    Helpful functions for creating, drawing, and manipulating board state.
  """
  require Jason
  alias Santorini.Board, as: Board

  @spec from_json(json :: String.t()) :: Board.t()
  def from_json(json) do
    Jason.decode!(json, [{:keys, :atoms}])
    |> (&struct(Board, &1)).()
    |> fix_players_list()
  end

  def to_json(board) do
    board
    |> unfix_players_list()
    |> Jason.encode!()
  end

  @spec read_board_from!(file :: String.t()) :: Board.t()
  def read_board_from!(file) do
    File.read!(file)
    |> from_json()
  end

  @spec draw(board :: Board.t(), device :: String.t()) :: Board.t()
  def draw(board, device \\ :stdio) do
    Stream.with_index(board.spaces)
    |> Stream.each(fn {row, row_num} ->
      Stream.with_index(row)
      |> Stream.each(fn {val, col_num} ->
        cond do
          [row_num, col_num] in Enum.at(board.players, 0).tokens ->
            IO.write(device, IO.ANSI.format([:blue_background, :white, "#{val}", :reset, " "]))

          [row_num, col_num] in Enum.at(board.players, 1).tokens ->
            IO.write(device, IO.ANSI.format([:white_background, :black, "#{val}", :reset, " "]))

          true ->
            IO.write(device, IO.ANSI.format(["#{val} "]))
        end
      end)
      |> Stream.run()

      IO.write(device, "\n")
    end)
    |> Stream.run()

    IO.write(
      device,
      IO.ANSI.format([:blue_background, :white, "#{Enum.at(board.players, 0).card}", :reset, "\n"])
    )

    IO.write(
      device,
      IO.ANSI.format([
        :white_background,
        :black,
        "#{Enum.at(board.players, 1).card}",
        :reset,
        "\n"
      ])
    )

    board
  end

  @spec action(board :: Board.t(), actionId :: Int) :: Board.t()
  def action(board, actionId) do
    <<player_id::1, workerId::1, moveDir::3, buildDir::3>> = <<actionId>>

    with moved <- Board.move_worker(board, player_id, workerId, moveDir),
         false <- moved == board,
         built <- Board.build(moved, player_id, workerId, buildDir),
         false <- built == moved do
      built
    else
      _ -> board
    end
  end

  @spec gen_random_starting_board(p1_card :: String.t(), p2_card :: String.t()) :: Board.t()
  def gen_random_starting_board(p1_card, p2_card) do
    random_players =
      Stream.transform(1..4, [], fn _, chosen ->
        choice =
          Stream.repeatedly(fn -> [Enum.random(0..4), Enum.random(0..4)] end)
          |> Stream.filter(fn pos -> pos not in chosen end)
          |> Stream.take(1)
          |> Enum.to_list()

        {choice, chosen ++ choice}
      end)
      |> Stream.chunk_every(2, 2)
      |> Stream.map(fn tokens -> %{card: "", tokens: tokens} end)
      |> Enum.to_list()

    Board.new()
    |> Board.set_players(random_players)
    |> Board.set_player_card(0, p1_card)
    |> Board.set_player_card(1, p2_card)
  end

  def game_state(board) do
    three_high_spaces =
      board.spaces
      |> Stream.with_index()
      |> Stream.flat_map(fn {row, rn} ->
        Stream.with_index(row)
        |> Stream.filter(fn {val, _cn} -> val == 3 end)
        |> Enum.map(fn {_val, cn} -> [rn, cn] end)
      end)

    board.players
    |> Stream.map(fn worker_positions ->
      Enum.reduce_while(worker_positions, false, fn pos, flag ->
        if pos in three_high_spaces do
          {:halt, true}
        else
          {:cont, flag}
        end
      end)
    end)
    |> (&Stream.zip([:you, :them], &1)).()
    |> Map.new()
  end

  def take_turn(board, strategy) do
    choose_option(board, 0, strategy)
    {wins?, board, path} = choose_option(board, 0, strategy)

    # if wins? do
    #   draw(board, :stderr)
    #   raise "Winner!"
    # else
    #   Board.next_turn(board)
    #   |> Board.swap_players()
    # end

    Board.next_turn(board)
    |> Board.swap_players()
  end

  def choose_option(board, player_id, strategy) do
    case strategy do
      :random ->
        options = get_action_options(board, 0)

        Enum.find(options, Enum.random(options), &elem(&1, 0))

      :semismart ->
        semi_smart_choice(board, player_id)
    end
  end

  def semi_smart_choice(board, player_id) do
    options = get_action_options(board, 0)

    Enum.find(
      options,
      Enum.chunk_by(options, fn {wins, delta_board, path} ->
        opponent_options = get_action_options(delta_board, 1)
        Enum.count(opponent_options, fn {op_wins, _, _} -> op_wins end)
      end)
      |> List.first()
      |> List.first(),
      fn {wins, _, _} -> wins end
    )
  end

  def get_action_options(board, player_id) do
    card = Enum.at(board.players, player_id).card

    Enum.concat(
      Module.concat(Santorini.Cards, card).get_action_options(board, player_id, 0),
      Module.concat(Santorini.Cards, card).get_action_options(board, player_id, 1)
    )
  end

  def get_surrounding_spaces(board, row, col) do
    for dR <- [-1, 0, 1],
        dC <- [-1, 0, 1],
        {dR, dC} != {0, 0},
        Board.valid_space(board, row + dR, col + dC),
        do: {row + dR, col + dC}
  end

  def get_surrounding_offsets(board, row, col) do
    for dR <- [-1, 0, 1],
        dC <- [-1, 0, 1],
        {dR, dC} != {0, 0},
        Board.valid_space(board, row + dR, col + dC),
        do: {dR, dC}
  end

  @spec get_available_move_offsets(board :: Board.t(), row :: Int, col :: Int) :: [{Int, Int}]
  def get_available_move_offsets(board, row, col) do
    get_surrounding_offsets(board, row, col)
    |> Stream.filter(fn {dR, dC} ->
      Board.can_move_between(board, row, col, row + dR, col + dC) and
        Board.space_unoccupied(board, row + dR, col + dC) and
        Board.space_height(board, row + dR, col + dC) < 4
    end)
    |> Enum.to_list()
  end

  @spec get_available_build_offsets(board :: Board.t(), row :: Int, col :: Int) :: [{Int, Int}]
  def get_available_build_offsets(board, row, col) do
    get_surrounding_offsets(board, row, col)
    |> Stream.filter(fn {dR, dC} ->
      Board.can_build_at(board, row + dR, col + dC) and
        Board.space_unoccupied(board, row + dR, col + dC)
    end)
    |> Enum.to_list()
  end

  def unfix_players_list(board) do
    Board.update_players(
      board,
      fn players ->
        players
        |> Stream.map(fn %{card: card, tokens: tokens} ->
          %{
            card: card,
            tokens:
              Stream.map(tokens, fn locs ->
                Stream.map(locs, fn val -> val + 1 end) |> Enum.to_list()
              end)
              |> Enum.to_list()
          }
        end)
        |> Enum.to_list()
      end
    )
  end

  def fix_players_list(board) do
    Board.update_players(
      board,
      fn players ->
        players
        |> Stream.map(fn %{card: card, tokens: tokens} ->
          %{
            card: card,
            tokens:
              Stream.map(tokens, fn locs ->
                Stream.map(locs, fn val -> val - 1 end) |> Enum.to_list()
              end)
              |> Enum.to_list()
          }
        end)
        |> Enum.to_list()
      end
    )
  end
end
