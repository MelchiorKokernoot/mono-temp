defmodule Systems.Org.ContentPage do
  use Systems.Content.Composer, :management_page

  alias Systems.Org

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Org.Public.get_node!(id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(%{"id" => id} = params, _, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "org_content/#{id}"

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        initial_tab: initial_tab
      )
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
