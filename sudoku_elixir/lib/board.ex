defmodule Board do
  @type board :: %Board{
          data: %{
            {non_neg_integer, non_neg_integer} => integer
          },
          m: non_neg_integer,
          n: non_neg_integer,
          bm: non_neg_integer,
          bn: non_neg_integer
        }
  defstruct [:data, :m, :n, :bm, :bn]

  @behaviour Access

  @impl Access
  def fetch(term, key) do
    Map.fetch(term.data, key)
  end

  @impl Access
  def get_and_update(data, key, function) do
    {val, new_data} = Map.get_and_update(data.data, key, function)
    new_board = %Board{data: new_data, m: data.m, n: data.n, bm: data.bm, bn: data.bn}
    {val, new_board}
  end

  @impl Access
  def pop(data, key) do
    {val, new_data} = Map.pop(data.data, key)
    new_board = %Board{data: new_data, m: data.m, n: data.n, bm: data.bm, bn: data.bn}
    {val, new_board}
  end

  @doc """
  Returns whether the given position has a value.

  """
  @spec has_value(board :: Board, row :: non_neg_integer, col :: non_neg_integer) :: boolean
  def has_value(board, row, col) when row >= 0 and col >= 0 do
    Map.has_key?(board.data, {row, col})
  end
end
