ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Stonks.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, StonksWeb.Endpoint.url())
