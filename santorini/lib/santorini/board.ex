defmodule Santorini.Board do
  defstruct [:players, :spaces, :turn]
  @type t :: %__MODULE__{players: [[{0..4, 0..4}]], spaces: [[1..4]], turn: integer}
end
