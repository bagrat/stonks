defmodule StonksWeb.StockLiveTest do
  use StonksWeb.ConnCase
  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  test "fetches details for each stock exactly once per mount", %{conn: conn} do
    test_stocks = [
      %Stonks.Stocks.Stock{
        symbol: "AAPL",
        name: "Apple Inc",
        currency: "USD",
        exchange: "NASDAQ"
      },
      %Stonks.Stocks.Stock{
        symbol: "MSFT",
        name: "Microsoft Corporation",
        currency: "USD",
        exchange: "NASDAQ"
      },
      %Stonks.Stocks.Stock{
        symbol: "GOOG",
        name: "Alphabet Inc",
        currency: "USD",
        exchange: "NASDAQ"
      }
    ]

    Stonks.StocksAPI.Mock
    |> expect(:list_stocks, 2, fn -> {:ok, test_stocks} end)
    |> expect(:get_stock_logo_url, 6, fn
      "AAPL", "NASDAQ" -> {:ok, "https://example.com/AAPL.png"}
      "MSFT", "NASDAQ" -> {:ok, "https://example.com/MSFT.png"}
      "GOOG", "NASDAQ" -> {:ok, "https://example.com/GOOG.png"}
    end)
    |> expect(:get_daily_time_series, 6, fn
      "AAPL", "NASDAQ" -> {:ok, []}
      "MSFT", "NASDAQ" -> {:ok, []}
      "GOOG", "NASDAQ" -> {:ok, []}
    end)

    {:ok, view, _html} = live(conn, "/")

    Process.sleep(100)

    assert render(view) =~ "https://example.com/AAPL.png"
    assert render(view) =~ "https://example.com/MSFT.png"
    assert render(view) =~ "https://example.com/GOOG.png"
  end
end
