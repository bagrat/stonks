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
end
