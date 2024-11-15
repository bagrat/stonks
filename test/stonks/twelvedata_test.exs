defmodule Stonks.TwelvedataTest do
  use ExUnit.Case, async: true

  test "list_stocks/0 should return stocks from NASDAQ and NYSE" do
    {:ok, stocks} = Stonks.Twelvedata.list_stocks()

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

  test "get_stock_statistics/1 should return stock statistics" do
    {:ok, statistics} = Stonks.Twelvedata.get_stock_statistics("AAPL")

    assert is_map(statistics)

    assert %{
             essentials: %{
               market_capitalization: _market_capitalization,
               fifty_two_week_high: _fifty_two_week_high_essential,
               fifty_two_week_low: _fifty_two_week_low_essential
             },
             valuation_and_profitability: %{
               trailing_pe: _trailing_pe,
               forward_pe: _forward_pe,
               peg_ratio: _peg_ratio,
               gross_margin: _gross_margin,
               profit_margin: _profit_margin,
               return_on_equity: _return_on_equity
             },
             growth_metrics: %{
               quarterly_revenue_growth: _quarterly_revenue_growth,
               quarterly_earnings_growth_yoy: _quarterly_earnings_growth_yoy
             },
             financial_health: %{
               total_cash: _total_cash,
               total_debt: _total_debt,
               debt_to_equity_ratio: _debt_to_equity_ratio,
               current_ratio: _current_ratio
             },
             market_trends: %{
               beta: _beta,
               fifty_two_week_high: _fifty_two_week_high,
               fifty_two_week_low: _fifty_two_week_low,
               fifty_day_moving_average: _day_50_ma,
               two_hundred_day_moving_average: _day_200_ma
             },
             dividend_information: %{
               forward_annual_dividend_yield: _forward_annual_dividend_yield,
               payout_ratio: _payout_ratio
             }
           } = statistics
  end

  test "get_stock_logo_url/1 should return the logo URL for a stock" do
    {:ok, logo_url} = Stonks.Twelvedata.get_stock_logo_url("AAPL")

    assert logo_url == "https://api.twelvedata.com/logo/apple.com"
  end
end
