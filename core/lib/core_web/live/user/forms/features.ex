defmodule CoreWeb.User.Forms.Features do
  use CoreWeb.LiveForm

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  alias Core.Accounts
  alias Core.Accounts.Features

  alias EyraUI.Selector.Selector
  alias EyraUI.Text.{Title2, Title3, BodyMedium}

  prop(props, :any, required: true)

  data(user, :any)
  data(entity, :any)
  data(gender_labels, :any)
  data(dominanthand_labels, :any)
  data(nativelanguage_labels, :any)

  data(changeset, :any)
  data(focus, :any, default: "")

  # Handle Selector Update
  def update(
        %{active_item_id: active_item_id, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :ok,
      socket
      |> save(entity, :auto_save, %{selector_id => active_item_id})
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  def update(%{id: id, props: %{user: user}}, socket) do
    entity = Accounts.get_features(user)

    gender_labels = Genders.labels(entity.gender)
    dominanthand_labels = DominantHands.labels(entity.dominant_hand)
    nativelanguage_labels = NativeLanguages.labels(entity.native_language)

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(gender_labels: gender_labels)
      |> assign(dominanthand_labels: dominanthand_labels)
      |> assign(nativelanguage_labels: nativelanguage_labels)
      |> update_ui()
    }
  end

  defp update_ui(%{assigns: %{entity: entity}} = socket) do
    update_ui(socket, entity)
  end

  defp update_ui(socket, entity) do
    gender_labels = Genders.labels(entity.gender)
    dominanthand_labels = DominantHands.labels(entity.dominant_hand)
    nativelanguage_labels = NativeLanguages.labels(entity.native_language)

    socket
    |> assign(gender_labels: gender_labels)
    |> assign(dominanthand_labels: dominanthand_labels)
    |> assign(nativelanguage_labels: nativelanguage_labels)
  end

  # Saving
  def save(socket, %Core.Accounts.Features{} = entity, type, attrs) do
    changeset = Features.changeset(entity, type, attrs)

    socket
    |> schedule_save(changeset)
    |> update_ui()
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <FormArea>
          <Title2>{{dgettext("eyra-account", "features.title")}}</Title2>
          <BodyMedium>{{dgettext("eyra-account", "features.description")}}</BodyMedium>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-account", "features.gender.title")}}</Title3>
          <Selector id={{:gender}} items={{ @gender_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-account", "features.nativelanguage.title")}}</Title3>
          <Selector id={{:native_language}} items={{ @nativelanguage_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-account", "features.dominanthand.title")}}</Title3>
          <Selector id={{:dominant_hand}} items={{ @dominanthand_labels }} type={{:radio}} parent={{ %{type: __MODULE__, id: @id} }} />
        </FormArea>
      </ContentArea>
    """
  end
end