defmodule Seecure.Repo do
  use Ecto.Repo,
    otp_app: :seecure,
    adapter: Ecto.Adapters.Postgres
end
