defmodule Systems.Routes do
  defmacro routes() do
    quote do
      use Systems.Subroutes, [
        :home,
        :admin,
        :support,
        :assignment,
        :campaign,
        :next_action,
        :notification,
        :promotion,
        :pool,
        :scholar,
        :lab,
        :data_donation
      ]
    end
  end
end
