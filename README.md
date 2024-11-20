# Stonks

Thank you for choosing Stonks!

To run the app locally please make sure you have Docker installed and then run:

```bash
docker-compose up
```

Then open the browser and navigate to [http://localhost:4004](http://localhost:4004).

## TODOs

- [x] Handle rate-limit errors from the Twelvedata API
  - [ ] Make the retry-after time global, not for individual requests
  - [x] Cancel pending rate-limited requestes for logos that are no longer visible on the stocks page
- [ ] DRY up Twelvedata client module to use the same code for both the API and the tests
- [ ] Extract rate-limiting from the Twelvedata API client
- [ ] Exclude tests using the real API when running `mix test`
- [ ] Implement a background job for the cache to sweep trhough expired values
- [ ] Come up with a strategy to sort the stock without having statistics for all
  - [ ] ~~maybe use the the average volume from the timeseries data - won't work, still need to fetch for all symbols~~
- [x] Add a loading state to the stock page
  - [ ] When loading takes more than X seconds, i.e. rate-limited, show the upgrade tip
  - [ ] Fix UI glitching when loading cached details quickly
- [ ] Add a tooltip for truncated company names
- [ ] Enable to run browser and liveview tests together without conflicts
- [ ] Extract stock card HTML into a component
- [ ] Remove timeseries HTML from the stock page after the chart is loaded
- [ ] Support mobile view
- [ ] Improve TwelveData API call tracking
  - [ ] Maybe track the summary instead of each call, of what interest is every call?
  - [ ] Possibly add an async layer in between, so that the API client doesn't have to wait for DB writes
- [ ] Add search
- [ ] Add details page for each stock showing candlestick chart for timeseries
- [x] Show average or last high and low on the stock card
