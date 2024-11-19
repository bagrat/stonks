defmodule Stonks.Metrics.TwelvedataRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "twelvedata_requests" do
    field :timestamp, :time
    field :url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(twelvedata_request, attrs) do
    twelvedata_request
    |> cast(attrs, [:url, :timestamp])
    |> validate_required([:url, :timestamp])
  end
end
