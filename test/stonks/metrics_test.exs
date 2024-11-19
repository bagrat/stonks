defmodule Stonks.MetricsTest do
  use Stonks.DataCase

  alias Stonks.Metrics

  describe "twelvedata_requests" do
    alias Stonks.Metrics.TwelvedataRequest

    import Stonks.MetricsFixtures

    @invalid_attrs %{timestamp: nil, url: nil}

    test "list_twelvedata_requests/0 returns all twelvedata_requests" do
      twelvedata_request = twelvedata_request_fixture()
      assert Metrics.list_twelvedata_requests() == [twelvedata_request]
    end

    test "get_twelvedata_request!/1 returns the twelvedata_request with given id" do
      twelvedata_request = twelvedata_request_fixture()
      assert Metrics.get_twelvedata_request!(twelvedata_request.id) == twelvedata_request
    end

    test "create_twelvedata_request/1 with valid data creates a twelvedata_request" do
      timestamp = DateTime.utc_now()
      valid_attrs = %{timestamp: timestamp, url: "some url"}

      assert {:ok, %TwelvedataRequest{} = twelvedata_request} =
               Metrics.create_twelvedata_request(valid_attrs)

      assert DateTime.diff(twelvedata_request.timestamp, timestamp) == 0
      assert twelvedata_request.url == "some url"
    end

    test "create_twelvedata_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Metrics.create_twelvedata_request(@invalid_attrs)
    end

    test "update_twelvedata_request/2 with valid data updates the twelvedata_request" do
      twelvedata_request = twelvedata_request_fixture()
      timestamp = DateTime.utc_now()
      update_attrs = %{timestamp: timestamp, url: "some updated url"}

      assert {:ok, %TwelvedataRequest{} = twelvedata_request} =
               Metrics.update_twelvedata_request(twelvedata_request, update_attrs)

      assert DateTime.diff(twelvedata_request.timestamp, timestamp) == 0
      assert twelvedata_request.url == "some updated url"
    end

    test "update_twelvedata_request/2 with invalid data returns error changeset" do
      twelvedata_request = twelvedata_request_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Metrics.update_twelvedata_request(twelvedata_request, @invalid_attrs)

      assert twelvedata_request == Metrics.get_twelvedata_request!(twelvedata_request.id)
    end

    test "delete_twelvedata_request/1 deletes the twelvedata_request" do
      twelvedata_request = twelvedata_request_fixture()
      assert {:ok, %TwelvedataRequest{}} = Metrics.delete_twelvedata_request(twelvedata_request)

      assert_raise Ecto.NoResultsError, fn ->
        Metrics.get_twelvedata_request!(twelvedata_request.id)
      end
    end

    test "change_twelvedata_request/1 returns a twelvedata_request changeset" do
      twelvedata_request = twelvedata_request_fixture()
      assert %Ecto.Changeset{} = Metrics.change_twelvedata_request(twelvedata_request)
    end
  end
end
