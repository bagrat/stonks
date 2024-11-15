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

- [ ] Handle rate-limit errors from the Twelvedata API
- [ ] DRY up Twelvedata client module to use the same code for both the API and the tests
- [ ] Exclude tests using the real API when running `mix test`
- [ ] Come up with a strategy to sort the stock without having statistics for all
