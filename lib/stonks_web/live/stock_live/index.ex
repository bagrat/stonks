defmodule StonksWeb.StockLive.Index do
  use StonksWeb, :live_view
  require Logger

  @stocks_per_page 3

  @impl true
  def mount(_params, _session, socket) do
    {:ok, all_stocks} =
      Stonks.StocksAPI.list_stocks()

    total_pages = (length(all_stocks) / @stocks_per_page) |> ceil()

    {:ok,
     socket
     |> assign(:total_pages, total_pages)
     |> assign(:all_stocks, all_stocks)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:EXIT, _pid, :normal}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, stocks_with_details}, socket) when is_reference(ref) do
    {:noreply, socket |> assign(:stocks, stocks_with_details)}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, :normal}, socket) do
    {:noreply, socket}
  end

  defp assign_stocks_for_page(socket) do
    stocks =
      socket.assigns.all_stocks
      |> Enum.slice((socket.assigns.current_page - 1) * @stocks_per_page, @stocks_per_page)

    stocks =
      stocks
      |> Enum.map(fn stock ->
        stock
        |> Map.put(:logo_url, nil)
        |> Map.put(:time_series, nil)
      end)

    Task.async(fn ->
      stocks
      |> Enum.map(fn stock ->
        timeseries_task =
          Task.async(fn ->
            Stonks.StocksAPI.get_daily_time_series(stock.symbol, stock.exchange)
          end)

        logo_task =
          Task.async(fn ->
            Stonks.StocksAPI.get_stock_logo_url(stock.symbol, stock.exchange)
          end)

        {:ok, time_series} = Task.await(timeseries_task, 5 * 60000)
        {:ok, logo_url} = Task.await(logo_task, 5 * 60000)

        stock
        |> Map.put(:time_series, time_series)
        |> Map.put(:logo_url, logo_url)
      end)
    end)

    socket
    |> assign(:stocks, stocks)
  end

  defp assign_pages_to_show(socket) do
    total_pages = socket.assigns.total_pages
    current_page = socket.assigns.current_page

    pages_to_show =
      cond do
        total_pages <= 6 ->
          1..total_pages

        current_page <= 3 ->
          [1, 2, 3, 4, 5, 6, :ellipsis, total_pages]

        current_page >= total_pages - 2 ->
          [1, :ellipsis] ++ Enum.to_list((total_pages - 5)..total_pages)

        true ->
          first_visible_page = current_page - 2
          last_visible_page = current_page + 2

          visible_pages =
            first_visible_page..last_visible_page
            |> Enum.to_list()

          [1, :ellipsis] ++ visible_pages ++ [:ellipsis, total_pages]
      end

    socket
    |> assign(:pages_to_show, pages_to_show)
  end

  defp apply_action(socket, :index, params) do
    requested_page =
      (params["page"] || "1")
      |> String.to_integer()

    current_page =
      requested_page
      |> max(1)
      |> min(socket.assigns.total_pages)

    socket
    |> assign(:page_title, "Stocks")
    |> assign(:current_page, current_page)
    |> assign_stocks_for_page()
    |> assign_pages_to_show()
    |> then(fn socket ->
      if requested_page != current_page do
        push_patch(socket, to: ~p"/?page=#{current_page}")
      else
        socket
      end
    end)
  end
end
