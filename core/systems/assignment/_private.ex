defmodule Systems.Assignment.Private do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  require Logger

  alias Systems.{
    Assignment,
    Workflow,
    Crew,
    Storage
  }

  def get_panel_url(%Assignment.Model{id: id, external_panel: external_panel}) do
    case external_panel do
      :liss -> ~p"/assignment/#{id}/liss"
      :ioresearch -> ~p"/assignment/#{id}/ioresearch?participant={id}&language=nl"
      :generic -> ~p"/assignment/#{id}/participate?participant={id}&language=nl"
    end
  end

  def get_preview_url(%Assignment.Model{id: id, external_panel: external_panel}, participant) do
    case external_panel do
      :liss ->
        ~p"/assignment/#{id}/liss?respondent=#{participant}&quest=quest&varname1=varname1&token=token&page=page"

      :ioresearch ->
        ~p"/assignment/#{id}/ioresearch?participant=#{participant}"

      _ ->
        ~p"/assignment/#{id}/participate?participant=#{participant}"
    end
  end

  def page_title_default(:assignment_intro), do: dgettext("eyra-assignment", "intro.page.title")

  def page_title_default(:assignment_support),
    do: dgettext("eyra-assignment", "support.page.title")

  def page_body_default(:assignment_intro), do: ""
  def page_body_default(:assignment_support), do: ""

  def allowed_external_panel_ids() do
    Keyword.get(config(), :external_panels, [])
  end

  defp config() do
    Application.get_env(:core, :assignment)
  end

  def connector_popup_module(:storage), do: Assignment.ConnectorPopupStorage
  def connector_popup_module(:panel), do: Assignment.ConnectorPopupPanel

  def connection_view_module(:storage), do: Assignment.ConnectionViewStorage
  def connection_view_module(:panel), do: Assignment.ConnectionViewPanel

  def connection_title(:storage, %{storage_endpoint: storage_endpoint}),
    do: connection_title(:storage, Storage.EndpointModel.special_field(storage_endpoint))

  def connection_title(:storage, storage_service_id),
    do: Storage.ServiceIds.translate(storage_service_id)

  def connection_title(:panel, %{external_panel: external_panel}),
    do: Assignment.ExternalPanelIds.translate(external_panel)

  def task_template(%{special: :data_donation}, %Workflow.ItemModel{id: item_id}) do
    ["item=#{item_id}"]
  end

  def task_identifier(
        %{special: :data_donation},
        %Workflow.ItemModel{id: item_id},
        %Crew.MemberModel{id: member_id}
      ) do
    ["item=#{item_id}", "member=#{member_id}"]
  end

  # Depricated
  def task_identifier(tool, user) do
    Logger.warn(
      "`Systems.Assignment.Private.task_identifier/2` is deprecated; call `task_identifier/3` instead."
    )

    [
      Atom.to_string(Frameworks.Concept.ToolModel.key(tool)),
      Integer.to_string(tool.id),
      Integer.to_string(user.id)
    ]
  end
end