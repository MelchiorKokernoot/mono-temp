defmodule Systems.Questionnaire.Public do
  @moduledoc """

  Questionnaire tools allow a researcher to setup a link to an external questionnaire
  tool. The participant goes through the flow described below:

  - Receive invitation to start a questionnaire (mail, push etc.).
  - Open questionnaire tool, this opens it on the platform and requires authentication.
  - The participant is then redirected to the questionnaire at a 3rd party web-application.
  - After completion the user is redirect back to the platform.
  - The platform registers the completion of this questionnaire for the participant.


  A researcher is required to configure the 3rd party application with a redirect
  link. The redirect link to be used is show on the questionnaire tool configuration
  screen (with copy button).

  IDEA: The tool requires a sucessful round-trip with a verify flow to ensure
  that everything is configured correctly.

  Participants need to be invited to a particular questionnaire explicitly. This avoids
  the situation where a new user joins a study and then can immediately complete
  previous questionnaires.

  Once a participant has completed a questionnaire they are no longer allowed to enter it
  a second time. The status is clearly shown when the attempt to do so.

  IDEA: A list of questionnaires can be access by the notification icon which is shown
  on all screens.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Core.Repo

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Questionnaire
  }

  @doc """
  Returns the list of questionnaire_tools.
  """
  def list_questionnaire_tools do
    Repo.all(Questionnaire.ToolModel)
  end

  @doc """
  Gets a single questionnaire_tool.

  Raises `Ecto.NoResultsError` if the Questionnaire tool does not exist.
  """
  def get_questionnaire_tool!(id), do: Repo.get!(Questionnaire.ToolModel, id)
  def get_questionnaire_tool(id), do: Repo.get(Questionnaire.ToolModel, id)

  @doc """
  Creates a questionnaire_tool.
  """
  def create_tool(attrs, auth_node) do
    %Questionnaire.ToolModel{}
    |> Questionnaire.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  @doc """
  Updates a questionnaire_tool.
  """
  def update_questionnaire_tool(%Questionnaire.ToolModel{} = questionnaire_tool, type, attrs) do
    questionnaire_tool
    |> Questionnaire.ToolModel.changeset(type, attrs)
    |> update_questionnaire_tool()
  end

  def update_questionnaire_tool(_, _, _), do: {:error, nil}

  def update_questionnaire_tool(changeset) do
    result =
      Multi.new()
      |> Repo.multi_update(:tool, changeset)
      |> Repo.transaction()

    with {:ok, %{tool: tool}} <- result do
      Signal.Public.dispatch!(:questionnaire_tool_updated, tool)
    end

    result
  end

  @doc """
  Deletes a questionnaire_tool.
  """
  def delete_questionnaire_tool(%Questionnaire.ToolModel{} = questionnaire_tool) do
    Repo.delete(questionnaire_tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking questionnaire_tool changes.
  """
  def change_questionnaire_tool(
        %Questionnaire.ToolModel{} = questionnaire_tool,
        type,
        attrs \\ %{}
      ) do
    Questionnaire.ToolModel.changeset(questionnaire_tool, type, attrs)
  end

  def copy(%Questionnaire.ToolModel{} = tool, auth_node) do
    %Questionnaire.ToolModel{}
    |> Questionnaire.ToolModel.changeset(:copy, Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def ready?(%Questionnaire.ToolModel{} = questionnaire_tool) do
    changeset =
      %Questionnaire.ToolModel{}
      |> Questionnaire.ToolModel.operational_changeset(Map.from_struct(questionnaire_tool))

    changeset.valid?
  end
end

defimpl Core.Persister, for: Systems.Questionnaire.ToolModel do
  def save(_tool, changeset) do
    case Systems.Questionnaire.Public.update_questionnaire_tool(changeset) do
      {:ok, %{tool: tool}} -> {:ok, tool}
      _ -> {:error, changeset}
    end
  end
end
