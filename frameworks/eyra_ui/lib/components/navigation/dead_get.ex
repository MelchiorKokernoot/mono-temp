defmodule EyraUI.Navigation.DeadGet do
  use Surface.Component

  prop(path, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
      <a
        class="cursor-pointer"
        href={{ @path }}
      >
        <slot />
      </a>
    """
  end
end