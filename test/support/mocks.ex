Mox.defmock(Stonks.StocksAPI.Mock, for: Stonks.StocksAPI)
Application.put_env(:stonks, :stocks_api, Stonks.StocksAPI.Mock)
