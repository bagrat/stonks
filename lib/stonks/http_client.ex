defmodule Stonks.HTTPClient do
  @callback request(method :: atom(), url :: String.t(), opts :: keyword()) ::
              {:ok, map()}
              | {:error, :rate_limited, pos_integer()}
              | {:error, String.t()}
end

defmodule Stonks.HTTPClient.Cached do
  use GenServer
  require Logger

  alias Stonks.GenericCache

  # Client API
  def start_link({cache_pid, opts}) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, cache_pid, name: name)
  end

  def get(server, url, opts \\ []) do
    GenServer.call(server, {:get, url, opts})
  end

  # Server Callbacks
  @impl true
  def init(cache_pid) do
    {:ok, %{cache_pid: cache_pid}}
  end

  @impl true
  def handle_call({:get, url, opts}, _from, state) do
    Logger.debug("handle_call with url: #{url}, opts: #{inspect(opts)}")

    headers = Keyword.get(opts, :headers, [])
    cache_ttl = Keyword.get(opts, :cache_ttl, 0)
    cache_key = cache_key("GET", url, headers)

    Logger.debug("Using implementation: #{inspect(impl())}")

    result =
      case GenericCache.get_cached(state.cache_pid, cache_key) do
        nil ->
          IO.inspect("Req #{url} #{inspect(opts)}")
          result = impl().request(:get, url, headers: headers)
          log_request_result(url, result)

          case result do
            {:ok, _} = success when cache_ttl > 0 ->
              GenericCache.put_cached(state.cache_pid, cache_key, success, cache_ttl)
              success

            other ->
              other
          end

        cached_result ->
          cached_result
      end

    {:reply, result, state}
  end

  defp log_request_result(url, result) do
    case result do
      {:ok, _} -> Logger.debug("Request to #{url} succeeded")
      {:error, :rate_limited, _} -> Logger.debug("Rate limited request to #{url}")
      _ -> Logger.debug("Failed request to #{url} result: #{inspect(result)}")
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

  defp impl do
    Application.get_env(:stonks, :http_client, Stonks.HTTPClient.Finch)
    |> IO.inspect()
  end
end

defmodule Stonks.HTTPClient.Finch do
  @behaviour Stonks.HTTPClient
  require Logger

  @impl true
  def request(method, url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])

    request = Finch.build(method, url, headers)

    case Finch.request(request, Stonks.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"status" => "error", "code" => 429}} ->
            {:error, :rate_limited, 60}

          {:ok, decoded} ->
            {:ok, decoded}

          {:error, _} ->
            {:error, "Failed to decode response: #{body}"}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
