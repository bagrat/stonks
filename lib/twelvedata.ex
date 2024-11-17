defmodule Stonks.StocksAPI do
  alias Stonks.Stocks.{Stock, Statistics, TimeseriesDataPoint}
  require Logger

  @callback list_stocks() :: {:ok, [Stock.t()]} | {:error, any()}
  @callback get_stock_logo_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback get_stock_statistics(String.t(), String.t()) ::
              {:ok, Statistics.t()} | {:error, any()}
  @callback get_daily_time_series(String.t(), String.t()) ::
              {:ok, [TimeseriesDataPoint.t()]} | {:error, any()}

  def list_stocks(), do: impl().list_stocks()

  def get_stock_logo_url(symbol, exchange) do
    impl().get_stock_logo_url(symbol, exchange)
  end

  def get_stock_statistics(symbol, exchange), do: impl().get_stock_statistics(symbol, exchange)
  def get_daily_time_series(symbol, exchange), do: impl().get_daily_time_series(symbol, exchange)

  defp impl() do
    Application.get_env(:stonks, :stocks_api, Stonks.StocksAPI.Twelvedata)
  end
end

defmodule Stonks.StocksAPI.Twelvedata do
  use GenServer
  require Logger
  alias Stonks.Stocks.{Stock, Statistics, TimeseriesDataPoint}

  @behaviour Stonks.StocksAPI

  # Client API
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def list_stocks_for_exchange(exchange) do
    GenServer.call(__MODULE__, {:list_stocks_for_exchange, exchange}, :infinity)
  end

  @impl true
  def list_stocks() do
    GenServer.call(__MODULE__, :list_stocks, :infinity)
  end

  @impl true
  def get_stock_logo_url(symbol, exchange) do
    GenServer.call(__MODULE__, {:get_stock_logo_url, symbol, exchange}, :infinity)
  end

  @impl true
  def get_stock_statistics(symbol, exchange) do
    GenServer.call(__MODULE__, {:get_stock_statistics, symbol, exchange}, :infinity)
  end

  @impl true
  def get_daily_time_series(symbol, exchange) do
    GenServer.call(__MODULE__, {:get_daily_time_series, symbol, exchange}, :infinity)
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    # Start with an empty queue and schedule immediate processing
    {:ok, %{waiting_queue: :queue.new()}}
  end

  @impl true
  def handle_call(request, {from_pid, _} = from, %{waiting_queue: queue} = state) do
    # Monitor the calling process
    ref = Process.monitor(from_pid)

    # Queue the request immediately
    Logger.debug("Queueing request #{inspect(request)}, current queue size: #{:queue.len(queue)}")
    updated_queue = :queue.in({request, from, DateTime.utc_now(), ref}, queue)

    send(self(), :process_queue)

    # Return immediately, letting the process_queue handle the request
    {:noreply, %{state | waiting_queue: updated_queue}}
  end

  @impl true
  def handle_info(:process_queue, %{waiting_queue: queue} = state) do
    Logger.debug("Processing queue, current queue size: #{:queue.len(queue)}")

    case :queue.out(queue) do
      {{:value, {request, from, _enqueued_at, ref}}, new_queue} ->
        case do_handle_request(request) do
          {:error, :rate_limited, retry_after} ->
            # If rate limited, re-queue with a future retry time
            retry_at = DateTime.add(DateTime.utc_now(), retry_after, :second)
            updated_queue = :queue.in({request, from, retry_at, ref}, new_queue)
            Logger.debug("Requeued request #{inspect(request)}")

            # Schedule next processing after the retry delay
            Process.send_after(self(), :process_queue, retry_after * 1000)
            {:noreply, %{state | waiting_queue: updated_queue}}

          result ->
            # Request succeeded, demonitor and reply
            Process.demonitor(ref, [:flush])
            GenServer.reply(from, result)

            # Schedule immediate processing of next request
            if :queue.len(new_queue) > 0 do
              send(self(), :process_queue)
            end

            {:noreply, %{state | waiting_queue: new_queue}}
        end

      {:empty, _} ->
        # Queue is empty, check again in a short while
        {:noreply, state}
    end
  end

  # Handle DOWN messages from monitored processes
  @impl true
  def handle_info({:DOWN, ref, :process, pid, _reason}, %{waiting_queue: queue} = state) do
    # Remove any queued requests from the terminated process
    updated_queue =
      queue
      |> :queue.to_list()
      |> Enum.reject(fn {_req, {from_pid, _}, _time, request_ref} ->
        from_pid == pid || request_ref == ref
      end)
      |> Enum.map(fn {req, from, time, ref} ->
        Logger.debug("Removing request #{inspect(req)} from #{inspect(from)}")
        {req, from, time, ref}
      end)
      |> :queue.from_list()

    {:noreply, %{state | waiting_queue: updated_queue}}
  end

  # Private request handlers
  defp do_handle_request({:list_stocks_for_exchange, exchange}) do
    do_list_stocks_for_exchange(exchange)
  end

  defp do_handle_request(:list_stocks) do
    do_list_stocks()
  end

  defp do_handle_request({:get_stock_logo_url, symbol, exchange}) do
    do_get_stock_logo_url(symbol, exchange)
  end

  defp do_handle_request({:get_stock_statistics, symbol, exchange}) do
    do_get_stock_statistics(symbol, exchange)
  end

  defp do_handle_request({:get_daily_time_series, symbol, exchange}) do
    do_get_daily_time_series(symbol, exchange)
  end

  # API Implementation
  defp do_list_stocks_for_exchange(exchange) do
    path = "stocks?exchange=#{exchange}"

    case make_request(path) do
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

      {:error, :rate_limited, retry_after} ->
        {:error, :rate_limited, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_list_stocks() do
    nasdaq_task = Task.async(fn -> do_list_stocks_for_exchange("NASDAQ") end)
    nyse_task = Task.async(fn -> do_list_stocks_for_exchange("NYSE") end)

    timeout_5_min = 5 * 60 * 1000

    with {:ok, nasdaq_stocks} <- Task.await(nasdaq_task, timeout_5_min),
         {:ok, nyse_stocks} <- Task.await(nyse_task, timeout_5_min) do
      {:ok, nasdaq_stocks ++ nyse_stocks}
    else
      {:error, :rate_limited, retry_after} -> {:error, :rate_limited, retry_after}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_get_stock_logo_url(symbol, exchange) do
    path = "logo?symbol=#{symbol}&exchange=#{exchange}"

    case make_request(path) do
      {:ok, %{"url" => url}} ->
        {:ok, url}

      {:ok, %{"code" => 404}} ->
        {:ok, ""}

      {:error, :rate_limited, retry_after} ->
        {:error, :rate_limited, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_get_stock_statistics(symbol, exchange) do
    path = "statistics?symbol=#{symbol}&exchange=#{exchange}"

    case make_request(path) do
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

      {:error, :rate_limited, retry_after} ->
        {:error, :rate_limited, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_get_daily_time_series(symbol, exchange) do
    path = "time_series?symbol=#{symbol}&interval=1day&exchange=#{exchange}"

    case make_request(path) do
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

      {:ok, %{"code" => 404}} ->
        {:ok, []}

      {:error, :rate_limited, retry_after} ->
        {:error, :rate_limited, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_request(path) do
    url = "https://api.twelvedata.com/#{path}"
    [api_key: api_key] = Application.fetch_env!(:stonks, :twelvedata)

    request =
      Finch.build(:get, url, [
        {"Authorization", "apikey #{api_key}"}
      ])

    result =
      case Finch.request(request, Stonks.Finch) do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"status" => "error", "code" => 429}} -> {:error, :rate_limited, 60}
            {:ok, body} -> {:ok, body}
            _ -> {:error, "Unexpected response body: #{inspect(body)}"}
          end

        {:ok, %Finch.Response{status: status}} ->
          {:error, "Request failed with status code: #{status}"}

        {:error, reason} ->
          {:error, reason}
      end

    case result do
      {:ok, _} ->
        Logger.debug("Request to #{url} succeeded")

      {:error, :rate_limited, _retry_after} ->
        Logger.debug("Rate limited request to #{url}")

      _ ->
        Logger.debug("Failed request to #{url} result: #{inspect(result)}")
    end

    result
  end
end
