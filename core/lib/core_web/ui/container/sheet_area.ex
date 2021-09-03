defmodule CoreWeb.UI.Container.SheetArea do
  @moduledoc """
    Restricted width container for forms.
  """
  use CoreWeb.UI.Component

  prop(class, :string, default: "")

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex justify-center {{ @class }}">
      <div class="flex-grow sm:max-w-sheet">
        <slot />
      </div>
    </div>
    """
  end
end