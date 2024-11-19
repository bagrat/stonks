defmodule Stonks.HTTPClient do
  @callback request(method :: atom(), url :: String.t(), opts :: keyword()) ::
              {:ok, map()}
              | {:error, :rate_limited, pos_integer()}
              | {:error, String.t()}
end

defmodule Stonks.HTTPClient.Finch do
  @behaviour Stonks.HTTPClient
  require Logger

  @impl true
  def request(method, url, opts \\ []) do
    headers = Keyword.get(opts, :headers, [])

    request = Finch.build(method, url, headers)

    case Finch.request(request, Stonks.Finch) do
      {:ok, %{status: 200} = response} ->
        {:ok, response}

      {:ok, %{status: status}} ->
        {:error, "Request failed with status code: #{status}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
