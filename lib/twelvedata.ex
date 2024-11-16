defmodule Stonks.Twelvedata do
  alias Stonks.Stocks.{Stock, Statistics, TimeseriesDataPoint}

  def list_stocks_for_exchange(exchange) do
    path = "stocks?exchange=#{exchange}"

    case make_request(path) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"data" => stocks}} ->
            {:ok,
             stocks
             |> Enum.map(fn stock ->
               %Stock{
                 symbol: stock["symbol"],
                 name: stock["name"],
                 currency: stock["currency"],
                 exchange: exchange
               }
             end)}

          {:error, _} ->
            {:error, "Failed to parse JSON for the #{exchange} exchange stocks"}
        end

      {:error, reason} ->
        {:error, "HTTP request error for the #{exchange} exchange stocks: #{reason}"}
    end
  end

  def list_stocks() do
    nasdaq_task = Task.async(fn -> list_stocks_for_exchange("NASDAQ") end)
    nyse_task = Task.async(fn -> list_stocks_for_exchange("NYSE") end)

    with {:ok, nasdaq_stocks} <- Task.await(nasdaq_task),
         {:ok, nyse_stocks} <- Task.await(nyse_task) do
      {:ok, nasdaq_stocks ++ nyse_stocks}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def get_stock_logo_url(symbol) do
    path = "logo?symbol=#{symbol}"

    case make_request(path) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"url" => url}} -> {:ok, url}
          {:error, _} -> {:error, "Failed to parse JSON for the #{symbol} stock logo"}
        end

      {:error, reason} ->
        {:error, "HTTP request error for the #{symbol} stock logo: #{reason}"}
    end
  end

  def get_stock_statistics(symbol) do
    path = "statistics?symbol=#{symbol}"

    case make_request(path) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"statistics" => stats}} ->
            {:ok,
             %Statistics{
               essentials: %Statistics.Essentials{
                 market_capitalization: stats["valuations_metrics"]["market_capitalization"],
                 fifty_two_week_high: stats["stock_price_summary"]["fifty_two_week_high"],
                 fifty_two_week_low: stats["stock_price_summary"]["fifty_two_week_low"]
               },
               valuation_and_profitability: %Statistics.ValuationAndProfitability{
                 trailing_pe: stats["valuations_metrics"]["trailing_pe"],
                 forward_pe: stats["valuations_metrics"]["forward_pe"],
                 peg_ratio: stats["valuations_metrics"]["peg_ratio"],
                 gross_margin: stats["financials"]["gross_margin"],
                 profit_margin: stats["financials"]["profit_margin"],
                 return_on_equity: stats["financials"]["return_on_equity_ttm"]
               },
               growth_metrics: %Statistics.GrowthMetrics{
                 quarterly_revenue_growth:
                   stats["financials"]["income_statement"]["quarterly_revenue_growth"],
                 quarterly_earnings_growth_yoy:
                   stats["financials"]["income_statement"]["quarterly_earnings_growth_yoy"]
               },
               financial_health: %Statistics.FinancialHealth{
                 total_cash: stats["financials"]["balance_sheet"]["total_cash_mrq"],
                 total_debt: stats["financials"]["balance_sheet"]["total_debt_mrq"],
                 debt_to_equity_ratio:
                   stats["financials"]["balance_sheet"]["total_debt_to_equity_mrq"],
                 current_ratio: stats["financials"]["balance_sheet"]["current_ratio_mrq"]
               },
               market_trends: %Statistics.MarketTrends{
                 beta: stats["stock_price_summary"]["beta"],
                 fifty_two_week_high: stats["stock_price_summary"]["fifty_two_week_high"],
                 fifty_two_week_low: stats["stock_price_summary"]["fifty_two_week_low"],
                 fifty_day_moving_average: stats["stock_price_summary"]["day_50_ma"],
                 two_hundred_day_moving_average: stats["stock_price_summary"]["day_200_ma"]
               },
               dividend_information: %Statistics.DividendInformation{
                 forward_annual_dividend_yield:
                   stats["dividends_and_splits"]["forward_annual_dividend_yield"],
                 payout_ratio: stats["dividends_and_splits"]["payout_ratio"]
               }
             }}

          {:error, _} ->
            {:error, "Failed to parse JSON for the #{symbol} stock statistics"}
        end

      {:error, reason} ->
        {:error, "HTTP request error for the #{symbol} stock statistics: #{reason}"}
    end
  end

  def get_daily_time_series(symbol) do
    path = "time_series?symbol=#{symbol}&interval=1day"

    case make_request(path) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, %{"values" => values}} ->
            {:ok,
             values
             |> Enum.map(fn value ->
               {:ok, datetime} = Date.from_iso8601(value["datetime"])

               %TimeseriesDataPoint{
                 datetime: datetime,
                 open: String.to_float(value["open"]),
                 high: String.to_float(value["high"]),
                 low: String.to_float(value["low"]),
                 close: String.to_float(value["close"]),
                 volume: String.to_integer(value["volume"])
               }
             end)}

          {:error, _} ->
            {:error, "Failed to parse JSON for the #{symbol} daily time series"}
        end

      {:error, reason} ->
        {:error, "HTTP request error for the #{symbol} daily time series: #{reason}"}
    end
  end

  defp make_request(path) do
    url = "https://api.twelvedata.com/#{path}"
    [api_key: api_key] = Application.fetch_env!(:stonks, :twelvedata)

    request =
      Finch.build(:get, url, [
        {"Authorization", "apikey #{api_key}"}
      ])

    case Finch.request(request, Stonks.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
