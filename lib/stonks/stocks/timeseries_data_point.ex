defmodule Stonks.Stocks.TimeseriesDataPoint do
  @enforce_keys [:datetime, :open, :high, :low, :close, :volume]
  defstruct [:datetime, :open, :high, :low, :close, :volume]
end
