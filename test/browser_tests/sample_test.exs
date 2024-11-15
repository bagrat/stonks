defmodule SampleTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  @tag :skip
  feature "Visiting the home page", %{session: session} do
    session
    |> visit("/")
    |> assert_text("Peace of mind from prototype to production.")
  end
end
