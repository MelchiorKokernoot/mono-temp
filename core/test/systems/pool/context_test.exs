defmodule Systems.Pool.ContextTest do
  use Core.DataCase
  alias Core.Factories

  alias Systems.Pool.Context

  setup do
    user = Factories.insert!(:member)
    pool = Factories.insert!(:pool, %{name: "test_pool"})

    {:ok, user: user, pool: pool}
  end

  describe "link/2" do
    test "link once succeeds", %{user: %{id: user_id} = user, pool: pool} do
      Context.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Context.get!(pool.id, [:participants])
    end

    test "link twice succeeds", %{user: %{id: user_id} = user, pool: pool} do
      # testing: on_conflict
      Context.link!(pool, user)
      Context.link!(pool, user)

      assert %{
               participants: [
                 %{
                   id: ^user_id
                 }
               ]
             } = Context.get!(pool.id, [:participants])
    end
  end

  describe "unlink/2" do
    test "unlink once succeeds", %{user: user, pool: pool} do
      Context.link!(pool, user)
      Context.unlink!(pool, user)

      assert %{
               participants: []
             } = Context.get!(pool.id, [:participants])
    end

    test "unlink twice succeeds", %{user: user, pool: pool} do
      Context.link!(pool, user)
      Context.unlink!(pool, user)
      Context.unlink!(pool, user)

      assert %{
               participants: []
             } = Context.get!(pool.id, [:participants])
    end
  end

  describe "update_pool_participations/3" do
    test "add", %{user: %{id: user_id} = user} do
      Context.update_pool_participations(user, ["vu_sbe_rpr_year1_2021"], [])

      assert %{
               participants: [%{id: ^user_id}]
             } = Context.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Context.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "add 2 for 2 pools", %{user: %{id: user_id} = user} do
      Context.update_pool_participations(
        user,
        [
          "vu_sbe_rpr_year1_2021",
          "vu_sbe_rpr_year2_2021"
        ],
        []
      )

      assert %{
               participants: [%{id: ^user_id}]
             } = Context.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: [%{id: ^user_id}]
             } = Context.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end

    test "remove 1 for 1 pools", %{user: user} do
      Context.update_pool_participations(user, ["vu_sbe_rpr_year1_2021"], [])
      Context.update_pool_participations(user, [], ["vu_sbe_rpr_year1_2021"])

      assert %{
               participants: []
             } = Context.get_by_name("vu_sbe_rpr_year1_2021", [:participants])
    end

    test "remove 2 for 2 pools", %{user: user} do
      Context.update_pool_participations(
        user,
        ["vu_sbe_iba_year1_2021", "vu_sbe_bk_year2_2021"],
        []
      )

      Context.update_pool_participations(user, [], [
        "vu_sbe_rpr_year1_2021",
        "vu_sbe_rpr_year2_2021"
      ])

      assert %{
               participants: []
             } = Context.get_by_name("vu_sbe_rpr_year1_2021", [:participants])

      assert %{
               participants: []
             } = Context.get_by_name("vu_sbe_rpr_year2_2021", [:participants])
    end
  end
end
