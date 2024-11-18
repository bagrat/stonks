defmodule Stonks.GenericCache do
  use Agent
  require Logger

  @default_ttl :timer.hours(24)

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Agent.start_link(fn -> %{} end, name: name)
  end

  def get_cached(pid, key) do
    Agent.get(pid, fn state ->
      case Map.get(state, key) do
        nil ->
          nil

        {value, timestamp, ttl} ->
          if stale?(timestamp, ttl), do: nil, else: value
      end
    end)
  end

  def put_cached(pid, key, value, ttl \\ @default_ttl)
  def put_cached(_pid, _key, _value, ttl) when ttl <= 0, do: :ok

  def put_cached(pid, key, value, ttl) do
    Agent.update(pid, fn state ->
      Map.put(state, key, {value, System.system_time(:millisecond), ttl})
    end)
  end

  defp stale?(timestamp, ttl) do
    now = System.system_time(:millisecond)
    now - timestamp > ttl
  end

  def clean_all(pid) do
    Agent.update(pid, fn _ -> %{} end)
  end
end
