defmodule Stonks.BrowserTests.StocksTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature
  import Wallaby.Query
  alias Wallaby

  import Mox

  setup :verify_on_exit!

  feature "Homepage shows first 3 stocks", %{session: session} do
    stocks_data =
      for i <- 1..10 do
        symbol = "STCK#{i}"
        exchange = if(rem(i, 2) == 0, do: "NASDAQ", else: "NYSE")

        stock =
          %Stonks.Stocks.Stock{
            symbol: symbol,
            name: "Stonky Company #{i}",
            currency: "USD",
            exchange: exchange
          }

        {{symbol, exchange}, {i, stock}}
      end
      |> Map.new()

    test_stocks =
      stocks_data
      |> Map.values()
      |> Enum.sort_by(fn {i, _stock} -> i end)
      |> Enum.map(fn {_i, stock} -> stock end)

    logos =
      stocks_data
      |> Enum.map(fn {key, {i, _stock}} -> {key, "/images/logo-#{i}.svg"} end)
      |> Map.new()

    Stonks.StocksAPI.Mock
    |> stub(:list_stocks, fn -> {:ok, test_stocks} end)
    |> stub(:get_stock_logo_url, fn symbol, exchange ->
      {:ok, logos[{symbol, exchange}]}
    end)
    |> stub(:get_daily_time_series, fn _symbol, _exchange ->
      {:ok, []}
    end)

    _stock_cards =
      session
      |> visit("/")
      |> find(css(".stock-card", count: 3))
      |> Enum.map(fn stock_card ->
        [stock_card, find(stock_card, css(".stock-symbol")), find(stock_card, css(".stock-name"))]
      end)
      |> Enum.with_index()
      |> Enum.map(fn {[stock_card, stock_symbol, stock_name], i} ->
        assert_text(stock_symbol, "STCK#{i + 1}")
        assert_text(stock_name, "Stonky Company #{i + 1}")

        src =
          stock_card
          |> find(css("img"))
          |> Element.attr("src")

        assert src =~ "/images/logo-#{i + 1}.svg"
      end)
  end
end
