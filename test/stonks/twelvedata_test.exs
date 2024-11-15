defmodule Stonks.TwelvedataTest do
  use ExUnit.Case, async: true

  test "list_stocks/0 should return stocks from NASDAQ and NYSE" do
    {:ok, stocks} = Stonks.Twelvedata.list_stocks()

    assert is_list(stocks)
    assert length(stocks) > 0

    exchanges =
      for stock <- stocks do
        assert %{
                 "symbol" => _symbol,
                 "exchange" => exchange,
                 "name" => _name,
                 "currency" => _currency
               } = stock

        exchange
      end
      |> Enum.uniq()

    assert length(exchanges) == 2
    assert "NASDAQ" in exchanges
    assert "NYSE" in exchanges
  end
end
