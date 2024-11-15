defmodule Stonks.Twelvedata do
  def list_stocks_for_exchange(exchange) do
    [api_key: api_key] = Application.fetch_env!(:stonks, :twelvedata)
    url = "https://api.twelvedata.com/stocks?apikey=#{api_key}&exchange=#{exchange}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => data}} -> {:ok, data}
          {:error, _} -> {:error, "Failed to parse JSON for the #{exchange} exchange stocks"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error,
         "Request for the #{exchange} exchange stocks failed with status code: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
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

  def get_stock_statistics(symbol) do
    [api_key: api_key] = Application.fetch_env!(:stonks, :twelvedata)
    url = "https://api.twelvedata.com/statistics?apikey=#{api_key}&symbol=#{symbol}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok,
           %{
             "statistics" => %{
               "valuations_metrics" => %{
                 "market_capitalization" => market_capitalization,
                 "trailing_pe" => trailing_pe,
                 "forward_pe" => forward_pe,
                 "peg_ratio" => peg_ratio
               },
               "financials" => %{
                 "gross_margin" => gross_margin,
                 "profit_margin" => profit_margin,
                 "return_on_equity_ttm" => return_on_equity,
                 "income_statement" => %{
                   "quarterly_revenue_growth" => quarterly_revenue_growth,
                   "quarterly_earnings_growth_yoy" => quarterly_earnings_growth_yoy
                 },
                 "balance_sheet" => %{
                   "total_cash_mrq" => total_cash,
                   "total_debt_mrq" => total_debt,
                   "total_debt_to_equity_mrq" => debt_to_equity_ratio,
                   "current_ratio_mrq" => current_ratio
                 }
               },
               "stock_price_summary" => %{
                 "beta" => beta,
                 "fifty_two_week_high" => fifty_two_week_high,
                 "fifty_two_week_low" => fifty_two_week_low,
                 "day_50_ma" => day_50_ma,
                 "day_200_ma" => day_200_ma
               },
               "dividends_and_splits" => %{
                 "forward_annual_dividend_yield" => forward_annual_dividend_yield,
                 "payout_ratio" => payout_ratio
               }
             }
           }} ->
            {:ok,
             %{
               essentials: %{
                 market_capitalization: market_capitalization,
                 fifty_two_week_high: fifty_two_week_high,
                 fifty_two_week_low: fifty_two_week_low
               },
               valuation_and_profitability: %{
                 trailing_pe: trailing_pe,
                 forward_pe: forward_pe,
                 peg_ratio: peg_ratio,
                 gross_margin: gross_margin,
                 profit_margin: profit_margin,
                 return_on_equity: return_on_equity
               },
               growth_metrics: %{
                 quarterly_revenue_growth: quarterly_revenue_growth,
                 quarterly_earnings_growth_yoy: quarterly_earnings_growth_yoy
               },
               financial_health: %{
                 total_cash: total_cash,
                 total_debt: total_debt,
                 debt_to_equity_ratio: debt_to_equity_ratio,
                 current_ratio: current_ratio
               },
               market_trends: %{
                 beta: beta,
                 fifty_two_week_high: fifty_two_week_high,
                 fifty_two_week_low: fifty_two_week_low,
                 fifty_day_moving_average: day_50_ma,
                 two_hundred_day_moving_average: day_200_ma
               },
               dividend_information: %{
                 forward_annual_dividend_yield: forward_annual_dividend_yield,
                 payout_ratio: payout_ratio
               }
             }}

          {:error, _} ->
            {:error, "Failed to parse JSON for the #{symbol} stock statistics"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error,
         "Request for the #{symbol} stock statistics failed with status code: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request error for the #{symbol} stock statistics: #{reason}"}
    end
  end
end
