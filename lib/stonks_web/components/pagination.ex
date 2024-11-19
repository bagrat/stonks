defmodule StonksWeb.Components.Pagination do
  use Phoenix.Component

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  attr :link_to, :string, default: nil

  slot :inner_block, required: true

  def pagination_button(assigns) when is_list(assigns.class) do
    pagination_button(assigns |> Map.put(:class, Enum.join(assigns.class, " ")))
  end

  def pagination_button(assigns) do
    ~H"""
    <button
      class={
        merge_classes(
          [
            "group disabled:pointer-events-none rounded-none h-full",
            "border-yellow-300 hover:bg-yellow-300",
            "px-3",
            "text-sm"
          ],
          @class
        )
      }
      {@rest}
    >
      <.link patch={@link_to} class="group-disabled:pointer-events-none">
        <%= render_slot(@inner_block) %>
      </.link>
    </button>
    """
  end

  defp merge_classes(class1, class2) when is_list(class1) and is_binary(class2) do
    class1 ++ [class2]
  end

  defp merge_classes(class1, class2) when is_list(class1) and is_list(class2) do
    class1 ++ class2
  end
end
