# Stonks

## Requirements

### Chrome and Chromedriver

- Install Chrome
- Install the matching version of Chromedriver. To do so run the following command using the `version` of Chrome you installed and the `platform` of your local machine. The supported platforms are:
  - `linux-x64`
  - `mac-arm64`
  - `mac-x64`
  - `win-x64`
  - `win-x32`

```bash
version="131.0.6757.0"
platform="mac-arm64"

curl -s https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json | jq -r --arg version "$version" --arg platform "$platform" \
  '.versions[] | select(.version == $version) | .downloads.chromedriver[] | select(.platform == $platform) | .url' | xargs curl -sO
```

## Phoenix setup

- Run `mix setup` to install and setup dependencies
- Run `mix test --trace` to run the tests and make sure everything is set up correctly
- Start Phoenix server with `mix phx.server` or inside IEx with `iex -S mix phx.server`

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
