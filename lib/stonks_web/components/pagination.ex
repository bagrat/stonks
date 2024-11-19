defmodule StonksWeb.Components.Pagination do
  use Phoenix.Component

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  attr :link_to, :string, default: nil
  attr :disabled, :boolean, default: false

  slot :inner_block, required: true

  def pagination_button(assigns) when is_list(assigns.class) do
    pagination_button(assigns |> Map.put(:class, Enum.join(assigns.class, " ")))
  end

  def pagination_button(assigns) do
    ~H"""
    <.link
      patch={@link_to}
      class={
        merge_classes(
          [
            @disabled && "pointer-events-none",
            not @disabled && "text-zinc-600 border-zinc-700",
            @disabled && "text-zinc-300 border-zinc-400",
            "border hover:bg-zinc-200 rounded-md",
            "h-full px-3 mx-1",
            "text-sm",
            "flex items-center justify-center"
          ],
          @class
        )
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp merge_classes(class1, class2) when is_list(class1) and is_binary(class2) do
    class1 ++ [class2]
  end

  defp merge_classes(class1, class2) when is_list(class1) and is_list(class2) do
    class1 ++ class2
  end

  defp merge_classes(class1, class2) when is_nil(class2) do
    class1
  end
end
