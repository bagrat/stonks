defmodule Stonks.Stocks.Statistics do
  defmodule Essentials do
    @enforce_keys [:market_capitalization, :fifty_two_week_high, :fifty_two_week_low]
    defstruct [:market_capitalization, :fifty_two_week_high, :fifty_two_week_low]
  end

  defmodule ValuationAndProfitability do
    @enforce_keys [
      :trailing_pe,
      :forward_pe,
      :peg_ratio,
      :gross_margin,
      :profit_margin,
      :return_on_equity
    ]
    defstruct [
      :trailing_pe,
      :forward_pe,
      :peg_ratio,
      :gross_margin,
      :profit_margin,
      :return_on_equity
    ]
  end

  defmodule GrowthMetrics do
    @enforce_keys [:quarterly_revenue_growth, :quarterly_earnings_growth_yoy]
    defstruct [:quarterly_revenue_growth, :quarterly_earnings_growth_yoy]
  end

  defmodule FinancialHealth do
    @enforce_keys [:total_cash, :total_debt, :debt_to_equity_ratio, :current_ratio]
    defstruct [:total_cash, :total_debt, :debt_to_equity_ratio, :current_ratio]
  end

  defmodule MarketTrends do
    @enforce_keys [
      :beta,
      :fifty_two_week_high,
      :fifty_two_week_low,
      :fifty_day_moving_average,
      :two_hundred_day_moving_average
    ]
    defstruct [
      :beta,
      :fifty_two_week_high,
      :fifty_two_week_low,
      :fifty_day_moving_average,
      :two_hundred_day_moving_average
    ]
  end

  defmodule DividendInformation do
    @enforce_keys [:forward_annual_dividend_yield, :payout_ratio]
    defstruct [:forward_annual_dividend_yield, :payout_ratio]
  end

  @enforce_keys [
    :essentials,
    :valuation_and_profitability,
    :growth_metrics,
    :financial_health,
    :market_trends,
    :dividend_information
  ]
  defstruct [
    :essentials,
    :valuation_and_profitability,
    :growth_metrics,
    :financial_health,
    :market_trends,
    :dividend_information
  ]
end
