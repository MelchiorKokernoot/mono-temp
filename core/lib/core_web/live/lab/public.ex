defmodule CoreWeb.Lab.Public do
  @moduledoc """
  The public promotion screen.
  """
  use CoreWeb, :live_view
  alias Core.Lab.Tools

  data(reservation, :any, default: nil)

  def mount(%{"id" => id}, _session, %{assigns: %{current_user: user}} = socket) do
    tool = Tools.get(id, preload: [:time_slots])

    {:ok,
     socket |> assign(:tool, tool) |> assign(:reservation, Tools.reservation_for_user(tool, user))}
  end

  def handle_event(
        "reserve-time-slot",
        %{"time-slot-id" => time_slot_id},
        %{assigns: %{current_user: user}} = socket
      ) do
    # FIXME: Add logic here to handle case when the time slot is in the past (show error message to the user)
    {:ok, reservation} =
      time_slot_id
      |> String.to_integer()
      |> Tools.reserve_time_slot(user)

    {:noreply, socket |> assign(:reservation, reservation)}
  end

  def handle_event(
        "cancel-reservation",
        _params,
        %{assigns: %{current_user: user, tool: tool}} = socket
      ) do
    Tools.cancel_reservation(tool, user)
    {:noreply, socket |> assign(:reservation, nil)}
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <div :if={{@reservation}}>
          You have made a reservation
          <button :on-click="cancel-reservation" data-confirm="Are you sure you want to cancel the reservation?">Cancel</button>
        </div>

        <table>
        <tr :for={{slot <- @tool.time_slots}}>
        <td>{{slot.start_time}}</td>
        <td>{{slot.location}}</td>
        <td>{{slot.number_of_seats}}</td>
          <td>
            <button
              :if={{is_nil(@reservation) || @reservation.time_slot_id != slot.id }}
              :on-click="reserve-time-slot" phx-value-time-slot-id={{slot.id}}
              data-confirm={{not is_nil(@reservation) and "Are you sure you want to switch your reservation?"}}>
                Apply
            </button>
          </td>
        </tr>
        </table>
      </ContentArea>
    """
  end
end