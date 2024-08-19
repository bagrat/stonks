import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :seecure, Seecure.Repo,
  username: "seecure",
  password: "seecure",
  port: 54321,
  hostname: "localhost",
  database: "seecure_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :seecure, SeecureWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "P+CmfxsEgLsaWskKjj4IM3SeNcUVG2K565edtBtUR0RN+tGzSUIKG4gw7j8jVM/S",
  server: false

# In test we don't send emails.
config :seecure, Seecure.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
