defmodule Core.NextActions.Live.NextAction do
  use EyraUI.Component

  defviewmodel(
    title: nil,
    description: nil,
    cta: nil,
    url: nil,
    highlighted?: false
  )

  prop(title_css, :css_class,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  prop(subtitle_css, :css_class, default: "text-bodysmall md:text-bodymedium font-body text-grey1")

  alias Surface.Components.LiveRedirect

  EyraUI.Button.PrimaryLiveViewButton

  prop(vm, :map, required: true)

  def colors(%{highlighted?: true}) do
    %{
      bg: "bg-tertiary",
      text: "text-grey1",
      button: "bg-grey1 text-white",
      icon: "text-grey1"
    }
  end

  def colors(_) do
    %{
      bg: "bg-grey5",
      text: "text-grey1",
      button: "bg-primary text-white",
      icon: "text-primary"
    }
  end

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{url(@vm)}} class="block">
      <div class="p-4 md:p-6 flex items-center space-x-4 rounded-md {{ colors((@vm)).bg }}">
        <div class="flex-grow">
          <div class="{{@title_css}} mb-2">
            {{title(@vm)}}
          </div>
          <div class={{@subtitle_css}}>
            {{description(@vm)}}
          </div>
        </div>
        <div class="hidden lg:block font-button text-button text-center p-3 rounded-md whitespace-nowrap {{colors(@vm).button}}">
          {{cta(@vm)}}
        </div>
        <div class="inline-block lg:hidden self-start mt-2px md:mt-1 ">
          <svg width="8" height="13" viewBox="0 0 8 13" class="fill-current {{colors(@vm).icon}}">
            <path d="M0.263916 11.34L4.84392 6.75L0.263916 2.16L1.67392 0.75L7.67392 6.75L1.67392 12.75L0.263916 11.34Z" />
          </svg>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end