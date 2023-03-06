defmodule Link.Layouts.Workspace.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder
  use Core.FeatureFlags

  import Core.Authorization, only: [can_access?: 2]
  import CoreWeb.Menu.Helpers

  import Systems.Admin.Public

  alias Systems.{Pool, Budget, Support, NextAction}

  @impl true
  def build_menu(:desktop_menu = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :link, user_state, active_item),
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  @impl true
  def build_menu(:tablet_menu = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :link, user_state, active_item),
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  @impl true
  def build_menu(:mobile_navbar = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :link, user_state, active_item),
      right: [
        alpine_item(menu_id, :menu, active_item, false, true)
      ]
    }
  end

  @impl true
  def build_menu(:mobile_menu = menu_id, socket, user_state, active_item) do
    %{
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  defp build_menu_first_part(socket, menu_id, %{email: email} = user_state, active_item) do
    next_action_count = NextAction.Public.count_next_actions(user_state)
    support_count = Support.Public.count_open_tickets()

    []
    |> append(
      live_item(socket, menu_id, :console, user_state, active_item),
      can_access?(user_state, Link.Console)
    )
    |> append(live_item(socket, menu_id, :admin, user_state, active_item), admin?(email))
    |> append(
      live_item(socket, menu_id, :support, user_state, active_item, true, support_count),
      admin?(email)
    )
    |> append(
      live_item(socket, menu_id, :recruitment, user_state, active_item),
      user_state.researcher
    )
    |> append(
      live_item(socket, menu_id, :pools, user_state, active_item),
      has_pools?(user_state)
    )
    |> append(live_item(socket, menu_id, :marketplace, user_state, active_item))
    |> append(live_item(socket, menu_id, :todo, user_state, active_item, true, next_action_count))
    |> append(
      live_item(socket, menu_id, :funding, user_state, active_item),
      can_access?(user_state, Budget.FundingPage)
    )
  end

  defp build_menu_second_part(socket, menu_id, %{email: email} = user_state, active_item) do
    [
      language_switch_item(socket, menu_id),
      live_item(socket, menu_id, :helpdesk, user_state, active_item),
      live_item(socket, menu_id, :settings, user_state, active_item),
      live_item(socket, menu_id, :profile, user_state, active_item),
      user_session_item(socket, menu_id, :signout, active_item)
    ]
    |> append(live_item(socket, menu_id, :debug, user_state, active_item), admin?(email))
  end

  defp append(list, extra, condition \\ true) do
    if condition, do: list ++ [extra], else: list
  end

  defp has_pools?(user) do
    not Enum.empty?(Pool.Public.list_owned(user))
  end
end
