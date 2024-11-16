defmodule StonksWeb.StockLive.Index do
  use StonksWeb, :live_view

  @stocks_per_page 3

  @impl true
  def mount(_params, _session, socket) do
    {:ok, all_stocks} = Stonks.Twelvedata.list_stocks()
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

  defp apply_action(socket, :index, params) do
    total_pages = socket.assigns.total_pages
    all_stocks = socket.assigns.all_stocks

    requested_page =
      (params["page"] || "1")
      |> String.to_integer()

    current_page =
      requested_page
      |> max(1)
      |> min(total_pages)

    stocks =
      all_stocks
      |> Enum.slice((current_page - 1) * @stocks_per_page, @stocks_per_page)

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

    enriched_stocks =
      stocks
      |> Enum.map(fn stock ->
        logo_task =
          Task.async(fn ->
            Stonks.Twelvedata.get_stock_logo_url(stock.symbol, stock.exchange)
          end)

        {stock, logo_task}
      end)
      |> Enum.map(fn {stock, logo_task} ->
        {:ok, logo_url} = Task.await(logo_task)

        stock
        |> Map.put(:logo_url, logo_url)
      end)

    socket =
      socket
      |> assign(:page_title, "Stocks")
      |> assign(:stocks, enriched_stocks)
      |> assign(:current_page, current_page)
      |> assign(:pages_to_show, pages_to_show)

    if requested_page != current_page do
      socket |> push_patch(to: ~p"/?current_page=#{current_page}")
    else
      socket
    end
  end
end
