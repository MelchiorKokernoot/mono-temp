defmodule Systems.Campaign.OverviewPage do
  @moduledoc """
   The recruitment page for researchers.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :recruitment
  use CoreWeb.UI.PlainDialog

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.PlainDialog
  alias CoreWeb.UI.SelectorDialog

  alias Frameworks.Utility.ViewModelBuilder
  alias Frameworks.Pixel.Button.PrimaryLiveViewButton
  alias Frameworks.Pixel.Card.DynamicCampaign
  alias Frameworks.Pixel.Grid.DynamicGrid
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Button.Action.Send
  alias Frameworks.Pixel.Button.Face.PlainIcon
  alias Frameworks.Pixel.ShareView

  data(campaigns, :list, default: [])
  data(popup, :any)
  data(selector_dialog, :map)

  alias Systems.{
    Campaign
  }

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        dialog: nil,
        popup: nil,
        selector_dialog: nil
      )
      |> update_campaigns()
      |> update_menus()
    }
  end

  defp update_campaigns(%{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    campaigns =
      user
      |> Campaign.Public.list_owned_campaigns(preload: preload)
      |> Enum.map(
        &ViewModelBuilder.view_model(&1, {__MODULE__, :card}, user, url_resolver(socket))
      )

    socket
    |> assign(
      campaigns: campaigns,
      dialog: nil,
      popup: nil,
      selector_dialog: nil
    )
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("delete", %{"item" => campaign_id}, socket) do
    item = dgettext("link-ui", "delete.confirm.campaign")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {
      :noreply,
      socket
      |> assign(campaign_id: String.to_integer(campaign_id))
      |> confirm("delete", title, text, confirm_label)
    }
  end

  @impl true
  def handle_event("delete_confirm", _params, %{assigns: %{campaign_id: campaign_id}} = socket) do
    Campaign.Public.delete(campaign_id)

    {
      :noreply,
      socket
      |> assign(
        campaign_id: nil,
        dialog: nil
      )
      |> update_campaigns()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(campaign_id: nil, dialog: nil)}
  end

  @impl true
  def handle_event("close_share_dialog", _, socket) do
    IO.puts("close_share_dialog")
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_event("share", %{"item" => campaign_id}, %{assigns: %{current_user: user}} = socket) do
    researchers =
      Core.Accounts.list_researchers([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    owners =
      campaign_id
      |> String.to_integer()
      |> Campaign.Public.get!()
      |> Campaign.Public.list_owners([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    popup = %{
      module: ShareView,
      content_id: campaign_id,
      content_name: dgettext("eyra-campaign", "share.dialog.content"),
      group_name: dgettext("eyra-campaign", "share.dialog.group"),
      users: researchers,
      shared_users: owners
    }

    {
      :noreply,
      socket |> assign(popup: popup)
    }
  end

  @impl true
  def handle_event("duplicate", %{"item" => campaign_id}, socket) do
    preload = Campaign.Model.preload_graph(:full)
    campaign = Campaign.Public.get!(String.to_integer(campaign_id), preload)

    Campaign.Assembly.copy(campaign)

    {
      :noreply,
      socket
      |> update_campaigns()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_campaign", _params, %{assigns: %{current_user: user}} = socket) do
    popup = %{
      module: Campaign.CreateForm,
      target: self(),
      user: user
    }

    {:noreply, socket |> assign(popup: popup)}
  end

  @impl true
  def handle_info(
        %{module: Systems.Campaign.CreateForm, action: %{redirect_to: campaign_id}},
        socket
      ) do
    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, Campaign.ContentPage, campaign_id))}
  end

  @impl true
  def handle_info(%{selector: :cancel}, socket) do
    {:noreply, socket |> assign(selector_dialog: nil)}
  end

  @impl true
  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Campaign.ContentPage, id))}
  end

  @impl true
  def handle_info(%{module: _, action: :close}, socket) do
    {:noreply, socket |> assign(popup: nil)}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{add: user, content_id: campaign_id}},
        socket
      ) do
    campaign_id
    |> Campaign.Public.get!()
    |> Campaign.Public.add_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{module: Frameworks.Pixel.ShareView, action: %{remove: user, content_id: campaign_id}},
        socket
      ) do
    campaign_id
    |> Campaign.Public.get!()
    |> Campaign.Public.remove_owner!(user)

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-survey", "title")} menus={@menus}>
      <Popup :if={@popup}>
        <div class="p-8 w-popup-md bg-white shadow-2xl rounded">
          <Dynamic.LiveComponent id={:campaign_overview_popup} module={@popup.module} {...@popup} />
        </div>
      </Popup>

      <div :if={@dialog != nil} class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20">
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog {...@dialog} />
        </div>
      </div>

      <div
        :if={@selector_dialog != nil}
        class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <SelectorDialog id={:selector_dialog} {...@selector_dialog} />
        </div>
      </div>

      <ContentArea>
        <MarginY id={:page_top} />
        <Case value={Enum.count(@campaigns) > 0}>
          <True>
            <div class="flex flex-row items-center justify-center">
              <div class="h-full">
                <Title2 margin="">{dgettext("link-survey", "campaign.overview.title")}</Title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Send vm={%{event: "create_campaign"}}>
                  <div class="sm:hidden">
                    <PlainIcon vm={label: dgettext("link-survey", "add.new.button.short"), icon: :forward} />
                  </div>
                  <div class="hidden sm:block">
                    <PlainIcon vm={label: dgettext("link-survey", "add.new.button"), icon: :forward} />
                  </div>
                </Send>
              </div>
            </div>
            <MarginY id={:title2_bottom} />
            <DynamicGrid>
              <div :for={campaign <- @campaigns}>
                <DynamicCampaign
                  path_provider={CoreWeb.Endpoint}
                  card={campaign}
                  click_event_data={%{action: :edit, id: campaign.edit_id}}
                />
              </div>
            </DynamicGrid>
            <Spacing value="L" />
          </True>
          <False>
            <Empty
              title={dgettext("link-survey", "empty.title")}
              body={dgettext("link-survey", "empty.description")}
              illustration="cards"
            />
            <Spacing value="L" />
            <PrimaryLiveViewButton
              label={dgettext("link-survey", "add.first.button")}
              event="create_campaign"
            />
          </False>
        </Case>
      </ContentArea>
    </Workspace>
    """
  end
end
