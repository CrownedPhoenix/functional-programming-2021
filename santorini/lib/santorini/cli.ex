defmodule Santorini.CLI do
  def main(args \\ []) do
    IO.read(:stdio, :line) |> Jason.decode() |> IO.inspect()
  end
end
