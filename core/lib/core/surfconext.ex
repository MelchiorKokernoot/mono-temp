defmodule Core.SurfConext do
  alias Core.Accounts.User
  alias Core.Repo
  alias Frameworks.Signal
  import Ecto.Query, warn: false

  require Logger

  defmodule SurfConextError do
    defexception [:message]
  end

  def list_by_users(users, preload \\ []) when is_list(users) do
    users
    |> Enum.map(& &1.id)
    |> list_by_user_ids(preload)
  end

  def list_by_user_ids(user_ids, preload \\ []) when is_list(user_ids) do
    from(sc in Core.SurfConext.User,
      where: sc.user_id in ^user_ids,
      preload: ^preload
    )
    |> Repo.all()
  end

  def get_user_by_student_id(student_id) do
    student_id_code = "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:#{student_id}"

    surfconext_query =
      from(sc in Core.SurfConext.User,
        where: ^student_id_code in sc.schac_personal_unique_code,
        select: sc.user_id
      )

    from(u in User, where: u.id in subquery(surfconext_query))
    |> Repo.one()
  end

  def get_user_by_sub(sub) do
    from(u in User,
      where:
        u.id in subquery(
          from(sc in Core.SurfConext.User, where: sc.sub == ^sub, select: sc.user_id)
        )
    )
    |> Repo.one()
  end

  def get_surfconext_user_by_user(%User{} = user) do
    get_surfconext_user_by_user_query(user)
    |> Repo.one()
  end

  def get_surfconext_user_by_user!(%User{} = user) do
    get_surfconext_user_by_user_query(user)
    |> Repo.one!()
  end

  defp get_surfconext_user_by_user_query(%User{id: id}) do
    from(surfconext_user in Core.SurfConext.User, where: surfconext_user.user_id == ^id)
  end

  def register_user(attrs) do
    affiliation = attrs |> Map.get("eduperson_affiliation", []) |> MapSet.new()

    fullname =
      ~w(given_name family_name)
      |> Enum.map(&Map.get(attrs, &1, ""))
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(" ")

    display_name = Map.get(attrs, "given_name", fullname)
    email = get_email(attrs)

    sso_info = %{
      email: email,
      displayname: display_name,
      profile: %{
        fullname: fullname
      },
      researcher: MapSet.member?(affiliation, "employee"),
      student:
        MapSet.member?(affiliation, "student") || String.ends_with?(email, "@student.vu.nl")
    }

    user = User.sso_changeset(%User{}, sso_info)

    with {:ok, surf_user} <-
           %Core.SurfConext.User{}
           |> Core.SurfConext.User.register_changeset(attrs)
           |> Ecto.Changeset.put_assoc(:user, user)
           |> Repo.insert() do
      Signal.Context.dispatch!(:user_created, %{user: surf_user.user})
      {:ok, surf_user}
    end
  end

  defp get_email(attrs) do
    case Map.get(attrs, "email") do
      nil -> raise SurfConextError, "No email found in user info #{attrs |> inspect()}"
      email -> email
    end
  end

  def update_user(%User{} = user, attrs) do
    get_surfconext_user_by_user!(user)
    |> Core.SurfConext.User.update_changeset(attrs)
    |> Repo.update!()
  end

  defmacro routes(otp_app) do
    quote bind_quoted: [otp_app: otp_app] do
      pipeline :surfconext_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
      end

      scope "/", Core.SurfConext do
        pipe_through([:surfconext_browser])
        get("/surfconext", AuthorizePlug, otp_app)
      end

      scope "/", Core.SurfConext do
        pipe_through([:browser])
        get("/surfconext/auth", CallbackController, :authenticate)
      end
    end
  end
end
