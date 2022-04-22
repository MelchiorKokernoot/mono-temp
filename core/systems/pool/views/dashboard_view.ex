defmodule Systems.Pool.DashboardView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Widget.{Metric, ValueDistribution, Progress}

  alias Systems.{
    Campaign,
    Bookkeeping
  }

  prop(user, :any, required: true)

  data(years, :map)

  def update(_params, socket) do
    first_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year1_2021"])
      |> Enum.map(& &1.balance_credit)

    second_year_rewards =
      Bookkeeping.Context.account_query(["wallet", "sbe_year2_2021"])
      |> Enum.map(& &1.balance_credit)

    years = [
      create_year(:first, first_year_rewards, 10),
      create_year(:second, second_year_rewards, 1)
    ]

    {
      :ok,
      socket |> assign(years: years)
    }
  end

  defp create_year(year, credits, scale) do
    study_program_codes = Core.Enums.StudyProgramCodes.values_by_year(year)
    year_string = Core.Enums.StudyProgramCodes.year_to_string(year)

    target = Core.Pools.target(year)

    active_credits = credits |> Enum.filter(&(&1 > 0 and &1 < target))
    passed_credits = credits |> Enum.filter(&(&1 >= target))

    truncated_credits =
      credits
      |> Enum.map(
        &if &1 < target do
          &1
        else
          target
        end
      )

    total_student_count = Core.Pools.count_students(study_program_codes)
    active_student_count = active_credits |> Enum.count()
    passed_student_count = passed_credits |> Enum.count()
    inactive_student_count = total_student_count - (active_student_count + passed_student_count)

    total_credits = Statistics.sum(truncated_credits) |> do_round()
    pending_credits = Campaign.Context.pending_rewards(year)
    target_credits = total_student_count * target

    %{
      title: dgettext("link-studentpool", "year.label", year: year_string),
      credits: %{
        label: dgettext("link-studentpool", "credit.distribution.title"),
        values: credits,
        scale: scale
      },
      progress: %{
        label: dgettext("link-studentpool", "credit.progress.title"),
        target_amount: target_credits,
        earned_amount: total_credits,
        pending_amount: pending_credits
      },
      metrics: [
        %{
          label: dgettext("link-studentpool", "inactive.students"),
          number: inactive_student_count,
          color:
            if inactive_student_count == 0 do
              :positive
            else
              :negative
            end
        },
        %{
          label: dgettext("link-studentpool", "active.students"),
          number: active_student_count,
          color:
            if active_student_count == 0 do
              :negative
            else
              :primary
            end
        },
        %{
          label: dgettext("link-studentpool", "passed.students"),
          number: passed_student_count,
          color:
            if passed_student_count == 0 do
              :negative
            else
              :positive
            end
        }
      ]
    }
  end

  defp do_round(number) when is_float(number),
    do: number |> Decimal.from_float() |> Decimal.round(2)

  defp do_round(number), do: number

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <div :for={year <- @years}>
          <Title2>{year.title}</Title2>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-8 h-full">
            <div :for={metric <- year.metrics}>
              <Metric {...metric}/>
            </div>
            <div class="col-span-3">
              <ValueDistribution {...year.credits} />
            </div>
            <div class="col-span-3">
              <Progress {...year.progress} />
            </div>
          </div>
          <Spacing value="XXL" />
        </div>
      </ContentArea>
    """
  end
end
