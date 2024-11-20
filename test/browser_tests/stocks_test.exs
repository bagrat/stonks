defmodule Stonks.BrowserTests.StocksTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature
  import Wallaby.Query
  alias Wallaby

  import Mox

  @stocks_per_page Application.compile_env(:stonks, :stocks_per_page, 7)

  setup :verify_on_exit!

  feature "Homepage shows first #{@stocks_per_page} stocks", %{session: session} do
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

        stock
      end
      |> Enum.sort_by(fn %Stonks.Stocks.Stock{symbol: symbol} -> symbol end)

    expected_stocks = stocks_data |> Enum.take(@stocks_per_page)

    logos =
      stocks_data
      |> Enum.map(fn stock ->
        {{stock.symbol, stock.exchange}, "/images/logo.svg?_=#{stock.symbol}-#{stock.exchange}"}
      end)
      |> Map.new()

    Stonks.StocksAPI.Mock
    |> stub(:list_stocks, fn -> {:ok, expected_stocks} end)
    |> stub(:get_stock_logo_url, fn symbol, exchange ->
      {:ok, logos[{symbol, exchange}]}
    end)
    |> stub(:get_daily_time_series, fn _symbol, _exchange ->
      {:ok, []}
    end)

    _stock_cards =
      session
      |> visit("/stocks")
      |> find(css(".stock-card", count: @stocks_per_page))
      |> Enum.map(fn stock_card ->
        [
          stock_card,
          find(stock_card, css(".stock-symbol")),
          find(stock_card, css(".stock-name")),
          find(stock_card, css(".stock-exchange"))
        ]
      end)
      |> Enum.map(fn
        [stock_card, stock_symbol_element, stock_name_element, stock_exchange_element] ->
          stock_symbol = Element.text(stock_symbol_element)
          stock_name = Element.text(stock_name_element)
          stock_exchange = Element.text(stock_exchange_element)

          expected_stock = stocks_data |> Enum.find(fn stock -> stock.symbol == stock_symbol end)

          assert_text(stock_symbol_element, expected_stock.symbol)
          assert_text(stock_name_element, expected_stock.name)
          assert_text(stock_exchange_element, expected_stock.exchange)

          src =
            stock_card
            |> find(css("img"))
            |> Element.attr("src")

          assert src =~ "/images/logo.svg?_=#{expected_stock.symbol}-#{expected_stock.exchange}"
      end)
  end
end
