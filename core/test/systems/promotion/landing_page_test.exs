defmodule Systems.Promotion.LandingPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.{
    Promotion,
    Crew,
    Budget
  }

  describe "show landing page for: campaign -> assignment -> questionnaire_tool" do
    setup [:login_as_member]

    setup do
      currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)
      budget = Budget.Factories.create_budget("test_1234", currency)

      pool =
        Factories.insert!(:pool, %{name: "test_1234", director: :citizen, currency: currency})

      questionnaire_tool =
        Factories.insert!(
          :questionnaire_tool,
          %{
            questionnaire_url: "https://eyra.co/fake_questionnaire"
          }
        )

      experiment =
        Factories.insert!(
          :experiment,
          %{
            questionnaire_tool: questionnaire_tool,
            subject_count: 10,
            duration: "10",
            language: "en",
            devices: [:desktop]
          }
        )

      assignment =
        Factories.insert!(
          :assignment,
          %{
            budget: budget,
            experiment: experiment,
            director: :campaign
          }
        )

      promotion =
        Factories.insert!(
          :promotion,
          %{
            director: :campaign,
            title: "This is a test title",
            themes: ["marketing", "econometrics"],
            expectations: "These are the expectations for the participants",
            description: "Something about this study",
            banner_title: "Banner Title",
            banner_subtitle: "Banner Subtitle",
            banner_photo_url: "https://eyra.co/image/1",
            banner_url: "https://eyra.co/member/1",
            marks: ["vu"]
          }
        )

      submission = Factories.insert!(:submission, %{reward_value: 500, pool: pool})
      author = Factories.build(:author)

      _campaign =
        Factories.insert!(:campaign, %{
          assignment: assignment,
          promotion: promotion,
          authors: [author],
          submissions: [submission]
        })

      %{promotion: promotion, assignment: assignment, submissions: [submission]}
    end

    test "Initial", %{conn: conn, promotion: promotion} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))
      assert html =~ "This is a test title"
      assert html =~ "These are the expectations for the participants"
      assert html =~ "Marketing, Econometrie"
      assert html =~ "Wat kun je verwachten?"
      assert html =~ "These are the expectations for the participants"
      assert html =~ "Over deze studie"
      assert html =~ "Something about this study"
      assert html =~ "This is a test title"
      assert html =~ "Ik doe mee"
      assert html =~ "Duur"
      assert html =~ "10 minuten"
      assert html =~ "Beloning"
      assert html =~ "ƒ5,00"
      assert html =~ "Status"
      assert html =~ "Open voor deelname"
      assert html =~ "Beschikbaar op:"
      assert html =~ "desktop.svg"
    end

    test "One member applied", %{conn: conn, promotion: promotion, assignment: assignment} do
      user = Factories.insert!(:member)
      {:ok, %{member: _member}} = Crew.Public.apply_member(assignment.crew, user)

      {:ok, _view, html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))
      assert html =~ "Open voor deelname"
    end

    test "Apply current user", %{conn: conn, promotion: promotion} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Promotion.LandingPage, promotion.id))

      html =
        view
        |> element("[phx-click=\"call-to-action-1\"]")
        |> render_click()

      # FIXME
      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = html
      assert to =~ "/assignment/"
    end
  end
end
