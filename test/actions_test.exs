defmodule ActionsTest do
  use ExUnit.Case

  alias OCCI.Model.Core

  defmodule ActionsModel do
    use OCCI.Model,
      scheme: "http://example.org/occi#"

    kind Compute,
      parent: Core.Resource,
      attributes: [
        killed: [default: false, type: OCCI.Types.Boolean],
	      status: [default: :active, type: [:active, :inactive, :schrodinger]]
      ] do

      action stop(entity, _attrs),
	      title: "Stop the compute entity",
	      attributes: [
	        method: [type: [:kill, :term], required: true],
	        reason: [type: OCCI.Types.String]
	      ] do
	      set(entity, :status, :inactive)
      end

      action action0,
	      title: "An action",
	      category: "http://example.org/an/arbitrary/name#action0"
    end

    # mixin "http://example.org/occi/compute#mixin",
    #   title: "A mixin"
    #   do
    #   action stop(entity, _attrs) do
    #     OCCI.Model.Core.Entity.set(entity, :status, :schrodinger)
    #   end
    # end
  end

  defmodule ActionsModel2 do
    use OCCI.Model,
      scheme: "http://example.org/occi2#"

    extends ActionsModel

    # action :'http://example.org/occi/compute/action#stop'.(entity, %{ method: method }) do
    #   OCCI.Model.Core.Entity.set(entity, :killed, true)
    # end
  end

  test "Launch action" do
    res = ActionsModel.Compute.new(%{ id: "/an_id" })
    assert match?(:inactive,
      Core.Entity.get(ActionsModel.Compute.stop(res, %{ method: :term }), :status))
  end

  test "Invalid action argument" do
    res = ActionsModel.Compute.new(%{ id: "/an_id" })
    assert_raise OCCI.Error, fn ->
      ActionsModel.Compute.stop(res, %{})
    end
  end

  test "Launch action with default implementation" do
    res = ActionsModel.Compute.new(%{ id: "/an_id" })
    assert match?(:active,
      Core.Entity.get(ActionsModel.Compute.action0(res, %{}), :status))
  end

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
