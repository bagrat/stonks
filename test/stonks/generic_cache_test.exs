defmodule Stonks.GenericCacheTest do
  use ExUnit.Case, async: true
  alias Stonks.GenericCache

  setup do
    name = :"cache_#{:erlang.unique_integer()}"
    {:ok, pid} = GenericCache.start_link(name: name)
    {:ok, pid: pid}
  end

  describe "get_cached/2" do
    test "returns nil for non-existent key", %{pid: pid} do
      assert GenericCache.get_cached(pid, "non_existent") == nil
    end

    test "returns cached value within TTL", %{pid: pid} do
      GenericCache.put_cached(pid, "key", "value", 2000)
      assert GenericCache.get_cached(pid, "key") == "value"
    end

    test "returns nil for expired value", %{pid: pid} do
      GenericCache.put_cached(pid, "key", "value", 1)
      Process.sleep(5)
      assert GenericCache.get_cached(pid, "key") == nil
    end
  end

  describe "put_cached/4" do
    test "stores value with default TTL", %{pid: pid} do
      GenericCache.put_cached(pid, "key", "value")
      assert GenericCache.get_cached(pid, "key") == "value"
    end

    test "stores value with custom TTL", %{pid: pid} do
      GenericCache.put_cached(pid, "key", "value", 1000)
      assert GenericCache.get_cached(pid, "key") == "value"
      Process.sleep(1100)
      assert GenericCache.get_cached(pid, "key") == nil
    end

    test "overwrites existing value", %{pid: pid} do
      GenericCache.put_cached(pid, "key", "value1")
      assert GenericCache.get_cached(pid, "key") == "value1"
      GenericCache.put_cached(pid, "key", "value2")
      assert GenericCache.get_cached(pid, "key") == "value2"
    end
  end

  describe "clean_all/1" do
    test "removes all cached values", %{pid: pid} do
      GenericCache.put_cached(pid, "key1", "value1")
      GenericCache.put_cached(pid, "key2", "value2")
      GenericCache.clean_all(pid)
      assert GenericCache.get_cached(pid, "key1") == nil
      assert GenericCache.get_cached(pid, "key2") == nil
    end
  end
end
