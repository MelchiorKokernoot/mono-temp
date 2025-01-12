defmodule Systems.Assignment.TemplateBenchmarkChallenge do
  alias Systems.Assignment
  alias Systems.Workflow

  defstruct [:id]

  defimpl Assignment.Template do
    use Gettext, backend: CoreWeb.Gettext

    def title(t), do: Assignment.Templates.translate(t.id)

    def content_flags(_t) do
      Assignment.ContentFlags.new(opt_out: [:language, :panel, :storage, :advert_in_pool])
    end

    def workflow(_t),
      do: %Workflow.Config{
        type: :many_mandatory,
        library: %Workflow.LibraryModel{
          render?: true,
          items: [
            %Workflow.LibraryItemModel{
              special: :fork_instruction,
              tool: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:fork_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.fork_instruction.description")
            },
            %Workflow.LibraryItemModel{
              special: :download_instruction,
              tool: :instruction_tool,
              title: Assignment.WorkflowItemSpecials.translate(:download_instruction),
              description:
                dgettext("eyra-assignment", "workflow_item.download_instruction.description")
            },
            %Workflow.LibraryItemModel{
              special: :submit,
              tool: :graphite_tool,
              title: Assignment.WorkflowItemSpecials.translate(:submit),
              description: dgettext("eyra-assignment", "workflow_item.submit.description")
            }
          ]
        },
        initial_items: [:fork_instruction, :download_instruction, :submit]
      }
  end
end
