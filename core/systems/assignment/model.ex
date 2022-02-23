defmodule Systems.Assignment.Model do
  @moduledoc """
  The assignment type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Assignment
  }

  schema "assignments" do
    belongs_to(:assignable_experiment, Assignment.ExperimentModel)
    belongs_to(:crew, Systems.Crew.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w()a

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(assignment), do: assignment.auth_node_id
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
  end

  def flatten(assignment) do
    assignment
    |> Map.take([:id, :crew, :director])
    |> Map.put(:assignable, assignable(assignment))
  end

  def assignable(%{assignable: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_experiment: assignable}) when not is_nil(assignable), do: assignable

  def assignable(%{id: id}) do
    raise "no assignable object available for assignment #{id}"
  end

  def preload_graph(:full) do
    [:crew, assignable_experiment: [lab_tool: [:time_slots], survey_tool: [:auth_node]]]
  end

  def preload_graph(_), do: []
end
