defmodule Stonks.Stocks.Stock do
  @enforce_keys [:symbol, :name, :currency, :exchange]
  defstruct [:symbol, :name, :currency, :exchange]
end
