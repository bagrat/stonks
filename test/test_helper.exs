ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Seecure.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, SeecureWeb.Endpoint.url())
