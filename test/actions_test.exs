defmodule ActionsTest do
  use ExUnit.Case

  alias OCCI.Model.Core

  defmodule ActionsModel do
    use OCCI.Model,
      scheme: "http://example.org/occi#"

    kind Kind0,
      parent: Core.Resource,
      attributes: [
        attr0: [type: OCCI.Types.String]
      ] do
      action(
        title: "An action",
        attributes: [
          reason: [type: OCCI.Types.String]
        ]
      )

      def action0(entity, %{reason: reason}) do
        OCCI.Entity.set(entity, :attr0, reason)
      end

      action(:action1)

      action(
        :action2,
        title: "An action with options"
      )
    end

    mixin Mixin0,
      title: "A mixin" do
      action(:action0)
    end
  end

  defmodule ActionsModel2 do
    use OCCI.Model,
      scheme: "http://example.org/occi2#"

    extends(ActionsModel)
  end

  test "Action definition" do
    assert match?(
             [
               "An action with options",
               "Action http://example.org/occi/kind0/action#action1",
               "An action"
             ],
             ActionsModel.Kind0.actions() |> Enum.map(& &1.title())
           )

    assert match?(
             [
               "Action http://example.org/occi/mixin0/action#action0"
             ],
             ActionsModel.Mixin0.actions() |> Enum.map(& &1.title())
           )
  end

  test "Action categories" do
    assert match?(
             [
               :"http://example.org/occi/kind0/action#action2",
               :"http://example.org/occi/kind0/action#action1",
               :"http://example.org/occi/kind0/action#action0"
             ],
             ActionsModel.Kind0.actions() |> Enum.map(& &1.category())
           )
  end

  # test "Launch action" do
  #   res = OCCI.Entity.call(ActionsModel.Kind0.new(%{ id: "/an_id" }), :action0, %{ reason: "whynot" })
  #   assert match?("whynot", Core.Entity.get(res, :attr0))
  # end

  # test "Invalid action argument" do
  #   res = ActionsModel.Kind0.new(%{ id: "/an_id" })
  #   assert_raise OCCI.Error, fn ->
  #     ActionsModel.Kind0.action0(res, %{})
  #   end
  # end

  # test "Launch action with default implementation" do
  #   res = ActionsModel.Compute.new(%{ id: "/an_id" })
  #   assert match?(:active,
  #     Core.Entity.get(ActionsModel.Compute.action0(res, %{}), :status))
  # end

  # test "Launch action with overriden implementation" do
  #   res = ActionsModel2.new("http://example.org/occi#compute", %{ id: "/an_id" })
  #   assert match?(true,
  #     Core.Entity.get(ActionsModel.Compute.stop(res, %{ method: :term }), :killed))
  # end

  # test "Launch action with implementation in mixin" do
  #   res = ActionsModel.new("http://example.org/occi#compute", %{ id: "/an_id" }, ["http://example.org/occi/compute#mixin"])
  #   assert match?(:schrodinger,
  #     Core.Entity.get(ActionsModel.Compute.stop(res, %{ method: :term }), :status))
  # end
end
