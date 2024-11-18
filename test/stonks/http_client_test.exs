defmodule Stonks.HTTPClient.CachedTest do
  use ExUnit.Case, async: true
  import Mox
  alias Stonks.GenericCache
  alias Stonks.HTTPClient

  setup do
    cache_name = :"cache_#{:erlang.unique_integer()}"
    client_name = :"client_#{:erlang.unique_integer()}"

    {:ok, cache_pid} = GenericCache.start_link(name: cache_name)

    {:ok, client_pid} =
      start_supervised({Stonks.HTTPClient.Cached, {cache_pid, [name: client_name]}})

    Mox.allow(HTTPClient.Mock, self(), client_pid)

    {:ok, cache_pid: cache_pid, client: client_pid}
  end

  setup :verify_on_exit!

  describe "get/3" do
    test "caches successful responses when cache_ttl > 0", %{client: client} do
      url = "https://api.example.com/test"
      headers = [{"Authorization", "token"}]

      expect(HTTPClient.Mock, :request, fn :get, ^url, headers: ^headers ->
        {:ok, %{"data" => "test"}}
      end)

      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers, cache_ttl: 1000)

      # Second call should use cache
      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers, cache_ttl: 1000)
    end

    test "doesn't cache when cache_ttl is 0", %{client: client} do
      url = "https://api.example.com/test"
      headers = [{"Authorization", "token"}]

      expect(HTTPClient.Mock, :request, 2, fn :get, ^url, [headers: ^headers] ->
        {:ok, %{"data" => "test"}}
      end)

      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers)

      # Second call should make a new request
      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers)
    end

    test "different headers create different cache keys", %{client: client} do
      url = "https://api.example.com/test"
      headers1 = [{"Authorization", "token1"}]
      headers2 = [{"Authorization", "token2"}]

      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: ^headers1] ->
        {:ok, %{"data" => "test1"}}
      end)

      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: ^headers2] ->
        {:ok, %{"data" => "test2"}}
      end)

      assert {:ok, %{"data" => "test1"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers1, cache_ttl: 1000)

      assert {:ok, %{"data" => "test2"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers2, cache_ttl: 1000)
    end

    test "header order doesn't affect cache key", %{client: client} do
      url = "https://api.example.com/test"
      headers1 = [{"Authorization", "token"}, {"Accept", "application/json"}]
      headers2 = [{"Accept", "application/json"}, {"Authorization", "token"}]

      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: _] ->
        {:ok, %{"data" => "test"}}
      end)

      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers1, cache_ttl: 1000)

      # Second call with reordered headers should use cache
      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers2, cache_ttl: 1000)
    end

    test "doesn't cache error responses", %{client: client} do
      url = "https://api.example.com/test"
      headers = [{"Authorization", "token"}]

      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: ^headers] ->
        {:error, "Failed"}
      end)

      assert {:error, "Failed"} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers, cache_ttl: 1000)

      # Second call should try again
      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: ^headers] ->
        {:ok, %{"data" => "test"}}
      end)

      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers, cache_ttl: 1000)
    end

    test "works without cache_pid", %{client: client} do
      url = "https://api.example.com/test"
      headers = [{"Authorization", "token"}]

      expect(HTTPClient.Mock, :request, fn :get, ^url, [headers: ^headers] ->
        {:ok, %{"data" => "test"}}
      end)

      assert {:ok, %{"data" => "test"}} =
               Stonks.HTTPClient.Cached.get(client, url, headers: headers)
    end
  end
end
