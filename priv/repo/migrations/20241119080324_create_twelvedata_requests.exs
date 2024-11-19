defmodule Stonks.Repo.Migrations.CreateTwelvedataRequests do
  use Ecto.Migration

  def change do
    create table(:twelvedata_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string
      add :timestamp, :time

      timestamps(type: :utc_datetime)
    end
  end
end
