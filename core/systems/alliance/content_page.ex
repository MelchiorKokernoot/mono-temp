defmodule Systems.Alliance.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Alliance

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Alliance.Public.get_tool!(String.to_integer(id))
  end

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "alliance_content/#{id}"

    {
      :ok,
      socket
      |> assign(initial_tab: initial_tab, tabbar_id: tabbar_id)
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_resize(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
      <.management_page
        title={@vm.title}
        menus={@menus}
        popup={@popup}
        dialog={@dialog}
        tabs={@vm.tabs}
        tabbar_id={@tabbar_id}
        initial_tab={@initial_tab}
        tabbar_size={@tabbar_size}
        show_errors={@show_errors}
        actions={@vm.actions}
      />
    """
  end
end
