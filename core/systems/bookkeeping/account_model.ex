defmodule Systems.Bookkeeping.AccountModel do
  use Ecto.Schema

  schema "book_accounts" do
    field(:identifier, {:array, :string})
    field(:balance_debit, :integer)
    field(:balance_credit, :integer)
    timestamps()
  end
end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Bookkeeping.AccountModel do
  import CoreWeb.Gettext

  alias Systems.{
    Campaign,
    Bookkeeping
  }

  def view_model(
        %Bookkeeping.AccountModel{
          id: id
        } = account,
        Link.Console,
        user,
        _url_resolver
      ) do
    title = title(account)

    target = target(account)

    subtitle =
      case target do
        target when target > 0 ->
          dgettext("eyra-assignment", "student.account.target", target: target)

        _ ->
          ""
      end

    balance = balance(account)

    pending_rewards = Campaign.Context.pending_rewards(user, year(account))

    %{
      id: id,
      title: title,
      subtitle: subtitle,
      target_amount: target,
      earned_amount: balance,
      pending_amount: pending_rewards
    }
  end

  defp balance(%{balance_debit: debit, balance_credit: credit}), do: credit - debit

  defp title(%{identifier: [_ | ["sbe_year1_2021" | _]]}),
    do: dgettext("eyra-assignment", "first.year") <> " SBE RPR"

  defp title(%{identifier: [_ | ["sbe_year2_2021" | _]]}),
    do: dgettext("eyra-assignment", "second.year") <> " SBE RPR"

  defp title(%{identifier: [_ | [name | _]]}), do: name

  defp target(%{identifier: [_ | [pool_name | _]]}), do: Core.Pools.target(pool_name)
  defp target(_), do: -1

  defp year(%{identifier: [_ | ["sbe_year1_2021" | _]]}), do: :first
  defp year(%{identifier: [_ | ["sbe_year2_2021" | _]]}), do: :second
end
