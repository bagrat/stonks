defmodule Stonks.StocksAPI do
  alias Stonks.Stocks.{Stock, TimeseriesDataPoint}
  require Logger

  @callback list_stocks() :: {:ok, [Stock.t()]} | {:error, any()}
  @callback get_stock_logo_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
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
  alias Stonks.Stocks.{Stock, TimeseriesDataPoint}
  alias Stonks.GenericCache
  @behaviour Stonks.StocksAPI

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
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
  def get_daily_time_series(symbol, exchange) do
    GenServer.call(__MODULE__, {:get_daily_time_series, symbol, exchange}, :infinity)
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    {:ok, cache_pid} = GenericCache.start_link(name: :"twelvedata_cache_#{inspect(self())}")
    {:ok, %{waiting_queue: :queue.new(), cache_pid: cache_pid, waiting?: false}}
  end

  @impl true
  def handle_call(
        request,
        {from_pid, _} = from,
        %{waiting_queue: queue} = state
      ) do
    # Monitor the calling process
    ref = Process.monitor(from_pid)

    # Queue the request immediately
    Logger.debug("Queueing request #{inspect(request)}, current queue size: #{:queue.len(queue)}")
    updated_queue = :queue.in({request, from, DateTime.utc_now(), ref}, queue)

    send(self(), {:process_queue, :wait})

    # Return immediately, letting the process_queue handle the request
    {:noreply, %{state | waiting_queue: updated_queue}}
  end

  @impl true
  def handle_info({:process_queue, :wait}, %{waiting?: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:process_queue, _}, %{waiting_queue: queue, cache_pid: cache_pid} = state) do
    Logger.debug("Processing queue, current queue size: #{:queue.len(queue)}")

    case :queue.out(queue) do
      {{:value, {request, from, _enqueued_at, ref}}, new_queue} ->
        case do_handle_request(request, cache_pid) do
          {:error, :rate_limited, retry_after} ->
            # If rate limited, re-queue with a future retry time
            retry_at = DateTime.add(DateTime.utc_now(), retry_after, :second)
            updated_queue = :queue.in({request, from, retry_at, ref}, new_queue)
            Logger.debug("Requeued request #{inspect(request)}")

            # Schedule next processing after the retry delay
            Process.send_after(self(), {:process_queue, :nowait}, retry_after * 1000)
            {:noreply, %{state | waiting_queue: updated_queue, waiting?: true}}

          result ->
            # Request succeeded, demonitor and reply
            Process.demonitor(ref, [:flush])
            GenServer.reply(from, result)

            if :queue.len(new_queue) > 0 do
              send(self(), {:process_queue, :nowait})
            end

            {:noreply, %{state | waiting_queue: new_queue, waiting?: false}}
        end

      {:empty, _} ->
        {:noreply, %{state | waiting?: false}}
    end
  end

  # Handle DOWN messages from monitored processes
  @impl true
  def handle_info(
        {:DOWN, ref, :process, pid, _reason},
        %{waiting_queue: queue} = state
      ) do
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
  defp do_handle_request({:list_stocks_for_exchange, exchange}, cache_pid) do
    do_list_stocks_for_exchange(exchange, cache_pid)
  end

  defp do_handle_request(:list_stocks, cache_pid) do
    do_list_stocks(cache_pid)
  end

  defp do_handle_request({:get_stock_logo_url, symbol, exchange}, cache_pid) do
    do_get_stock_logo_url(symbol, exchange, cache_pid)
  end

  defp do_handle_request({:get_daily_time_series, symbol, exchange}, cache_pid) do
    do_get_daily_time_series(symbol, exchange, cache_pid)
  end

  # API Implementation
  defp do_list_stocks_for_exchange(exchange, cache_pid) do
    path = "stocks?exchange=#{exchange}"

    case make_request(path, cache_pid) do
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

  defp do_list_stocks(cache_pid) do
    nasdaq_task = Task.async(fn -> do_list_stocks_for_exchange("NASDAQ", cache_pid) end)
    nyse_task = Task.async(fn -> do_list_stocks_for_exchange("NYSE", cache_pid) end)

    timeout_5_min = 5 * 60 * 1000

    with {:ok, nasdaq_stocks} <- Task.await(nasdaq_task, timeout_5_min),
         {:ok, nyse_stocks} <- Task.await(nyse_task, timeout_5_min) do
      {:ok, nasdaq_stocks ++ nyse_stocks}
    else
      {:error, :rate_limited, retry_after} -> {:error, :rate_limited, retry_after}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_get_stock_logo_url(symbol, exchange, cache_pid) do
    path = "logo?symbol=#{symbol}&exchange=#{exchange}"

    case make_request(path, cache_pid) do
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

  defp do_get_daily_time_series(symbol, exchange, cache_pid) do
    path = "time_series?symbol=#{symbol}&interval=1day&exchange=#{exchange}"

    case make_request(path, cache_pid) do
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

  defp make_request(path, cache_pid) do
    url = "https://api.twelvedata.com/#{path}"
    [api_key: api_key] = Application.fetch_env!(:stonks, :twelvedata)

    headers = [{"Authorization", "apikey #{api_key}"}]
    cache_key = cache_key("GET", url, headers)
    cached_value = GenericCache.get_cached(cache_pid, cache_key)

    case cached_value do
      nil ->
        case http_client().request(
               :get,
               url,
               headers: headers
             ) do
          {:ok, %{status: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, %{"status" => "error", "code" => code} = body} ->
                case code do
                  429 ->
                    Logger.warning("Rate limited by Twelvedata, retrying in 60 seconds")
                    {:error, :rate_limited, 60}

                  _ ->
                    {:ok, body}
                end

              {:ok, body} ->
                GenericCache.put_cached(cache_pid, cache_key, body, get_ttl_for_path(path))

                Stonks.Metrics.create_twelvedata_request(%{
                  url: url,
                  timestamp: DateTime.utc_now()
                })

                {:ok, body}

              {:error, reason} ->
                {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        {:ok, cached_value}
    end
  end

  defp http_client, do: Application.get_env(:stonks, :http_client, Stonks.HTTPClient.Finch)

  defp get_ttl_for_path(path) do
    cond do
      # Logo URLs rarely change
      String.contains?(path, "logo") -> :timer.hours(24 * 7)
      # Time series need frequent updates
      String.contains?(path, "time_series") -> :timer.minutes(15)
      # Default TTL
      true -> :timer.hours(24)
    end
  end

  defp cache_key(method, url, headers) do
    headers_string =
      headers
      |> Enum.sort()
      |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
      |> Enum.join("|")

    :crypto.hash(:sha256, "#{method}|#{url}|#{headers_string}")
    |> Base.encode16()
  end
end
