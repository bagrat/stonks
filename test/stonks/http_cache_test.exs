defmodule Stonks.HTTPCacheTest do
  use ExUnit.Case, async: true
  alias Stonks.HTTPCache

  setup do
    HTTPCache.clean_all()
    :ok
  end

  describe "get_cached/1" do
    test "returns nil for non-existent key" do
      assert HTTPCache.get_cached("non_existent") == nil
    end

    test "returns cached value within TTL" do
      HTTPCache.put_cached("key", "value", 2000)
      assert HTTPCache.get_cached("key") == "value"
    end

    test "returns nil for expired value" do
      HTTPCache.put_cached("key", "value", 1)
      Process.sleep(5)
      assert HTTPCache.get_cached("key") == nil
    end
  end

  describe "put_cached/3" do
    test "stores value with default TTL" do
      HTTPCache.put_cached("key", "value")
      assert HTTPCache.get_cached("key") == "value"
    end

    test "stores value with custom TTL" do
      HTTPCache.put_cached("key", "value", 1000)
      assert HTTPCache.get_cached("key") == "value"
      Process.sleep(1100)
      assert HTTPCache.get_cached("key") == nil
    end

    test "overwrites existing value" do
      HTTPCache.put_cached("key", "value1")
      assert HTTPCache.get_cached("key") == "value1"

      HTTPCache.put_cached("key", "value2")
      assert HTTPCache.get_cached("key") == "value2"
    end
  end

  describe "clean_all/0" do
    test "removes all cached values" do
      HTTPCache.put_cached("key1", "value1")
      HTTPCache.put_cached("key2", "value2")
      HTTPCache.clean_all()
      assert HTTPCache.get_cached("key1") == nil
      assert HTTPCache.get_cached("key2") == nil
    end
  end

  describe "cache behavior" do
    test "handles multiple values independently" do
      HTTPCache.put_cached("key1", "value1", 1000)
      HTTPCache.put_cached("key2", "value2", 10)

      assert HTTPCache.get_cached("key1") == "value1"
      assert HTTPCache.get_cached("key2") == "value2"

      Process.sleep(20)
      assert HTTPCache.get_cached("key1") == "value1"
      assert HTTPCache.get_cached("key2") == nil
    end

    test "handles complex data structures" do
      value = %{
        data: [1, 2, 3],
        nested: %{key: "value"},
        tuple: {:ok, "success"}
      }

      HTTPCache.put_cached("complex", value)
      assert HTTPCache.get_cached("complex") == value
    end

    test "handles large number of entries" do
      for i <- 1..1000 do
        HTTPCache.put_cached("key#{i}", "value#{i}")
      end

      for i <- 1..1000 do
        assert HTTPCache.get_cached("key#{i}") == "value#{i}"
      end
    end
  end

  describe "edge cases" do
    test "handles nil values" do
      HTTPCache.put_cached("nil_key", nil)
      assert HTTPCache.get_cached("nil_key") == nil
    end

    test "handles empty string keys" do
      HTTPCache.put_cached("", "empty_key")
      assert HTTPCache.get_cached("") == "empty_key"
    end

    test "handles zero TTL" do
      HTTPCache.put_cached("key", "value", 0)
      assert HTTPCache.get_cached("key") == nil
    end

    test "handles negative TTL" do
      HTTPCache.put_cached("key", "value", -1)
      assert HTTPCache.get_cached("key") == nil
    end
  end

  describe "concurrent access" do
    test "handles concurrent reads and writes" do
      # Start multiple processes that read and write simultaneously
      tasks =
        for i <- 1..100 do
          Task.async(fn ->
            HTTPCache.put_cached("concurrent_key", "value#{i}")
            HTTPCache.get_cached("concurrent_key")
          end)
        end

      # All operations should complete without errors
      results = Task.await_many(tasks)
      assert length(results) == 100
    end
  end
end
