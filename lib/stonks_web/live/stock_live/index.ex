defmodule StonksWeb.StockLive.Index do
  use StonksWeb, :live_view
  require Logger

  @stocks_per_page 3

  @impl true
  def mount(_params, _session, socket) do
    {:ok, all_stocks} = Stonks.Twelvedata.list_stocks()
    total_pages = (length(all_stocks) / @stocks_per_page) |> ceil()

    {:ok,
     socket
     |> assign(:total_pages, total_pages)
     |> assign(:all_stocks, all_stocks)
     |> assign(:logo_tasks, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({ref, {:ok, logo_url}}, socket) when is_reference(ref) do
    # Find the stock that matches this task reference
    case Enum.find(socket.assigns.logo_tasks, fn {_stock, task_ref} -> task_ref == ref end) do
      {stock, _} ->
        # Update the stock's logo URL in the stocks list
        updated_stocks =
          Enum.map(socket.assigns.all_stocks, fn s ->
            if s.symbol == stock.symbol && s.exchange == stock.exchange do
              Map.put(s, :logo_url, logo_url)
            else
              s
            end
          end)

        socket =
          socket
          |> assign(:all_stocks, updated_stocks)
          |> assign_stocks_for_page()

        # {:noreply, assign(socket, :stocks, updated_stocks)}
        {:noreply, socket}

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, :normal}, socket) do
    # Remove the completed task from our task list
    updated_tasks =
      Enum.reject(socket.assigns.logo_tasks, fn {_, task_ref} -> task_ref == ref end)

    {:noreply, assign(socket, :logo_tasks, updated_tasks)}
  end

  defp assign_stocks_for_page(socket) do
    stocks =
      socket.assigns.all_stocks
      |> Enum.slice((socket.assigns.current_page - 1) * @stocks_per_page, @stocks_per_page)

    # Start tasks for fetching logos
    stock_without_logo_urls =
      stocks
      |> Enum.filter(fn stock -> Map.get(stock, :logo_url) == nil end)

    logo_tasks =
      stock_without_logo_urls
      |> Enum.map(fn stock ->
        task =
          Task.async(fn ->
            case Stonks.Twelvedata.get_stock_logo_url(stock.symbol, stock.exchange) do
              {:ok, url} -> {:ok, url}
              # Handle errors gracefully
              {:error, _} -> {:ok, nil}
            end
          end)

        {stock, task.ref}
      end)

    stocks =
      stocks
      |> Enum.map(fn stock ->
        case Map.get(stock, :logo_url) do
          nil -> Map.put(stock, :logo_url, :loading)
          _ -> stock
        end
      end)

    socket
    |> assign(:stocks, stocks)
    |> assign(:logo_tasks, socket.assigns.logo_tasks ++ logo_tasks)
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
        push_patch(socket, to: ~p"/?current_page=#{current_page}")
      else
        socket
      end
    end)
  end
end
