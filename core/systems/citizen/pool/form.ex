defmodule Systems.Citizen.Pool.Form do
  use CoreWeb, :live_component

  require Logger

  import Frameworks.Pixel.Form
  alias Frameworks.Utility.EctoHelper
  alias Frameworks.Pixel.DropdownSelector
  alias Frameworks.Pixel.Text

  alias Systems.{
    Budget,
    Pool
  }

  @default_values %{"director" => "citizen", "target" => 0}

  # Initial update create
  @impl true
  def update(%{id: id, pool: nil, user: user, locale: locale}, socket) do
    title = dgettext("link-citizen", "pool.create.title")

    pool = %Pool.Model{}
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        pool: nil,
        user: user,
        locale: locale,
        pool: pool,
        changeset: changeset,
        validate_changeset?: false
      )
      |> update_currencies()
      |> update_selected_currency()
      |> compose_child(:currency_selector)
      |> init_buttons()
    }
  end

  # Initial update edit
  @impl true
  def update(%{id: id, pool: pool, user: user, locale: locale}, socket) do
    title = dgettext("link-citizen", "pool.edit.title")
    changeset = Pool.Model.prepare(pool)

    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        user: user,
        locale: locale,
        pool: pool,
        changeset: changeset,
        validate_changeset?: true
      )
      |> update_currencies()
      |> update_selected_currency()
      |> update_options()
      |> compose_child(:currency_selector)
      |> init_buttons()
    }
  end

  @impl true
  def compose(:currency_selector, %{options: options, selected_currency: selected_currency}) do
    selected_option_index = Enum.find_index(options, &(&1.id == selected_currency.id))

    %{
      module: DropdownSelector,
      params: %{
        options: options,
        selected_option_index: selected_option_index
      }
    }
  end

  defp update_currencies(socket) do
    currencies =
      Budget.Public.list_bank_accounts(currency: Budget.CurrencyModel.preload_graph(:full))
      |> Enum.map(& &1.currency)

    socket |> assign(currencies: currencies)
  end

  defp update_options(%{assigns: %{currencies: currencies, locale: locale}} = socket) do
    options =
      Enum.map(currencies, fn currency ->
        %{
          id: currency.id,
          value: Budget.CurrencyModel.title(currency, locale)
        }
      end)

    socket |> assign(options: options)
  end

  defp update_selected_currency(
         %{assigns: %{budget: %{currency: %{id: _id} = currency}}} = socket
       ) do
    socket |> assign(selected_currency: currency)
  end

  defp update_selected_currency(%{assigns: %{currencies: [currency | _]}} = socket) do
    socket |> assign(selected_currency: currency)
  end

  defp update_selected_currency(socket) do
    socket |> assign(selected_currency: nil)
  end

  defp init_buttons(%{assigns: %{myself: myself}} = socket) do
    socket
    |> assign(
      buttons: [
        %{
          action: %{type: :submit},
          face: %{type: :primary, label: dgettext("link-citizen", "pool.submit.button")}
        },
        %{
          action: %{type: :send, event: "cancel", target: myself},
          face: %{type: :label, label: dgettext("eyra-ui", "cancel.button")}
        }
      ]
    )
  end

  @impl true
  def handle_event("change", %{"model" => attrs}, socket) do
    {
      :noreply,
      socket |> change(attrs)
    }
  end

  @impl true
  def handle_event("submit", %{"model" => attrs}, socket) do
    attrs = Map.merge(@default_values, attrs)

    {
      :noreply,
      socket |> handle_submit(attrs)
    }
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply, socket |> send_event(:parent, "pool_cancelled")}
  end

  @impl true
  def handle_event(
        "dropdown_selected",
        %{option: %{id: id}},
        %{assigns: %{currencies: currencies}} = socket
      ) do
    selected_currency = currencies |> Enum.find(&(&1.id == id))
    {:noreply, socket |> assign(selected_currency: selected_currency)}
  end

  @impl true
  def handle_event("dropdown_toggle", _payload, socket) do
    {:noreply, socket |> assign(currency_error: nil)}
  end

  defp change(%{assigns: %{pool: pool, validate_changeset?: validate_changeset?}} = socket, attrs) do
    socket
    |> apply_change(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate(validate_changeset?)
    )
  end

  defp apply_change(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :change) do
      {:ok, _pool} -> socket |> assign(changeset: changeset)
      {:error, changeset} -> socket |> assign(changeset: changeset)
    end
  end

  defp handle_submit(%{assigns: %{pool: %{currency: %{id: _id}} = pool}} = socket, attrs) do
    # Edit modus
    socket
    |> apply_submit(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate()
      |> Pool.Model.submit()
    )
  end

  defp handle_submit(
         %{assigns: %{pool: pool, user: user, selected_currency: selected_currency}} = socket,
         attrs
       ) do
    # Create modus
    socket
    |> apply_submit(
      pool
      |> Pool.Model.change(attrs)
      |> Pool.Model.validate()
      |> Pool.Model.submit(user, selected_currency)
    )
  end

  defp apply_submit(socket, changeset) do
    case EctoHelper.upsert(changeset) do
      {:ok, _pool} ->
        socket |> send_event(:parent, "pool_saved")

      {:error, changeset} ->
        socket |> assign(changeset: changeset)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title3><%= @title %></Text.title3>
      <.spacing value="XS" />
      <.form id="citizen_form" :let={form} for={@changeset} phx-submit="submit" phx-target={@myself} >
        <.text_input form={form} field={:name} debounce="0" label_text={dgettext("link-citizen", "pool.name.label")} />
        <.text_input form={form}
          field={:virtual_icon}
          debounce="0"
          maxlength="2"
          label_text={dgettext("link-citizen", "pool.icon.label")}
        />

        <%= if @currency_selector do %>
          <Text.form_field_label id={:currency_label}>
            <%= dgettext("link-citizen", "pool.currency.label") %>
          </Text.form_field_label>
          <.spacing value="XXS" />
          <.child name={:currency_selector} fabric={@fabric} />
        <% end %>

        <.spacing value="M" />
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </.form>
    </div>
    """
  end
end
