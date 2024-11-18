defmodule Stonks.HTTPCache do
  use Agent
  require Logger

  @default_ttl :timer.hours(24)

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_cached(key) do
    Agent.get(__MODULE__, fn state ->
      case Map.get(state, key) do
        nil ->
          nil

        {value, timestamp, ttl} ->
          if stale?(timestamp, ttl) do
            nil
          else
            value
          end
      end
    end)
  end

  def put_cached(key, value, ttl \\ @default_ttl)
  def put_cached(_key, _value, ttl) when ttl <= 0, do: :ok

  def put_cached(key, value, ttl) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, key, {value, System.system_time(:millisecond), ttl})
    end)
  end

  defp stale?(timestamp, ttl) do
    now = System.system_time(:millisecond)
    now - timestamp > ttl
  end

  def clean_all do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end
end
