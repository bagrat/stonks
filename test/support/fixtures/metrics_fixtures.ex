defmodule Stonks.MetricsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stonks.Metrics` context.
  """

  @doc """
  Generate a twelvedata_request.
  """
  def twelvedata_request_fixture(attrs \\ %{}) do
    {:ok, twelvedata_request} =
      attrs
      |> Enum.into(%{
        timestamp: DateTime.utc_now(),
        url: "some url"
      })
      |> Stonks.Metrics.create_twelvedata_request()

    twelvedata_request
  end
end
