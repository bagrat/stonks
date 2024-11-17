defmodule Stonks.TwelvedataTest do
  use ExUnit.Case, async: true

  test "list_stocks/0 should return stocks from NASDAQ and NYSE" do
    {:ok, stocks} = Stonks.StocksAPI.Twelvedata.list_stocks()

    assert is_list(stocks)
    assert length(stocks) > 0

    exchanges =
      for stock <- stocks do
        assert %{
                 symbol: _symbol,
                 exchange: exchange,
                 name: _name,
                 currency: _currency
               } = stock

        exchange
      end
      |> Enum.uniq()

    assert length(exchanges) == 2
    assert "NASDAQ" in exchanges
    assert "NYSE" in exchanges
  end

  test "get_stock_logo_url/1 should return the logo URL for a stock" do
    {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")

    assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
  end

  test "get_daily_time_series/1 should return the daily time series for a stock" do
    {:ok, timeseries} = Stonks.StocksAPI.Twelvedata.get_daily_time_series("TSLA", "NASDAQ")

    assert is_list(timeseries)
    assert length(timeseries) == 30

    for data_point <- timeseries do
      assert %Stonks.Stocks.TimeseriesDataPoint{
               datetime: datetime,
               open: open,
               high: high,
               low: low,
               close: close,
               volume: volume
             } = data_point

      assert %Date{} = datetime
      assert is_float(open)
      assert is_float(high)
      assert is_float(low)
      assert is_float(close)
      assert is_integer(volume)
    end
  end

  test "ensure all stocks are in USD so that we can safely emit it in the UI" do
    {:ok, stocks} = Stonks.StocksAPI.Twelvedata.list_stocks()

    assert Enum.all?(stocks, fn stock -> stock.currency == "USD" end)
  end

  @tag :skip
  @tag timeout: 3 * 60_000
  test "ensure rate-limited requests are awaited until the rate limit is lifted" do
    Stonks.StocksAPI.Twelvedata.start_link()

    for _ <- 1..15 do
      {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
    end
  end
end
