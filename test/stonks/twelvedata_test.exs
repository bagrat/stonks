defmodule Stonks.TwelvedataTest do
  use Stonks.DataCase

  import Mox

  # @tag :skip
  # describe "Twelvedata Real API" do
  #   test "list_stocks/0 should return stocks from NASDAQ and NYSE" do
  #     {:ok, stocks} = Stonks.StocksAPI.Twelvedata.list_stocks()

  #     assert is_list(stocks)
  #     assert length(stocks) > 0

  #     exchanges =
  #       for stock <- stocks do
  #         assert %{
  #                  symbol: _symbol,
  #                  exchange: exchange,
  #                  name: _name,
  #                  currency: _currency
  #                } = stock

  #         exchange
  #       end
  #       |> Enum.uniq()

  #     assert length(exchanges) == 2
  #     assert "NASDAQ" in exchanges
  #     assert "NYSE" in exchanges
  #   end

  #   test "get_stock_logo_url/1 should return the logo URL for a stock" do
  #     {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")

  #     assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
  #   end

  #   test "get_daily_time_series/1 should return the daily time series for a stock" do
  #     {:ok, timeseries} = Stonks.StocksAPI.Twelvedata.get_daily_time_series("TSLA", "NASDAQ")

  #     assert is_list(timeseries)
  #     assert length(timeseries) == 30

  #     for data_point <- timeseries do
  #       assert %Stonks.Stocks.TimeseriesDataPoint{
  #                datetime: datetime,
  #                open: open,
  #                high: high,
  #                low: low,
  #                close: close,
  #                volume: volume
  #              } = data_point

  #       assert %Date{} = datetime
  #       assert is_float(open)
  #       assert is_float(high)
  #       assert is_float(low)
  #       assert is_float(close)
  #       assert is_integer(volume)
  #     end
  #   end

  #   test "ensure all stocks are in USD so that we can safely emit it in the UI" do
  #     {:ok, stocks} = Stonks.StocksAPI.Twelvedata.list_stocks()

  #     assert Enum.all?(stocks, fn stock -> stock.currency == "USD" end)
  #   end
  # end

  @tag :skip
  @tag timeout: 3 * 60_000
  test "ensure rate-limited requests are awaited until the rate limit is lifted" do
    Stonks.StocksAPI.Twelvedata.start_link()

    for _ <- 1..15 do
      {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
    end
  end

  setup do
    Supervisor.terminate_child(Stonks.Supervisor, Stonks.StocksAPI.Twelvedata)
    Supervisor.restart_child(Stonks.Supervisor, Stonks.StocksAPI.Twelvedata)

    Mox.allow(Stonks.HTTPClient.Mock, self(), Stonks.StocksAPI.Twelvedata)

    :ok
  end

  describe "Twelvedata caching" do
    test "successful requests are cached" do
      Stonks.HTTPClient.Mock
      |> expect(:request, fn :get,
                             "https://api.twelvedata.com/logo?symbol=TSLA&exchange=NASDAQ",
                             _opts ->
        {:ok,
         %{
           status: 200,
           body: Jason.encode!(%{url: "https://api.twelvedata.com/logo/tesla.com"})
         }}
      end)

      {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      assert logo_url == "https://api.twelvedata.com/logo/tesla.com"

      {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
    end

    test "unsuccessful requests are not cached" do
      Stonks.HTTPClient.Mock
      |> expect(:request, fn :get,
                             "https://api.twelvedata.com/logo?symbol=TSLA&exchange=NASDAQ",
                             _opts ->
        {:error, :unknown}
      end)
      |> expect(:request, fn :get,
                             "https://api.twelvedata.com/logo?symbol=TSLA&exchange=NASDAQ",
                             _opts ->
        {:ok,
         %{
           status: 200,
           body: Jason.encode!(%{url: "https://api.twelvedata.com/logo/tesla.com"})
         }}
      end)

      {:error, :unknown} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")

      {:ok, logo_url} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      assert logo_url == "https://api.twelvedata.com/logo/tesla.com"
    end
  end

  describe "Twelvedata metrics" do
    test "successful requests metrics are recorded in DB" do
      Stonks.HTTPClient.Mock
      |> expect(:request, 2, fn :get, url, _opts ->
        {:ok, %{status: 200, body: Jason.encode!(%{url: "anything"})}}
      end)

      {:ok, _} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("TSLA", "NASDAQ")
      {:ok, _} = Stonks.StocksAPI.Twelvedata.get_stock_logo_url("RND", "NASDAQ")

      assert [tesla_record, rnd_record] = Stonks.Metrics.list_twelvedata_requests()

      now = DateTime.utc_now()
      assert tesla_record.url == "https://api.twelvedata.com/logo?symbol=TSLA&exchange=NASDAQ"
      assert DateTime.diff(tesla_record.timestamp, now, :millisecond) < 500
      assert rnd_record.url == "https://api.twelvedata.com/logo?symbol=RND&exchange=NASDAQ"
      assert DateTime.diff(rnd_record.timestamp, now, :millisecond) < 500
    end

    test "unsuccessful requests are not logged" do
      Stonks.HTTPClient.Mock
      |> expect(:request, fn :get, _, _ -> {:error, :unknown} end)
    end
  end
end
