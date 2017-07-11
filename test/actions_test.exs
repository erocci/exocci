defmodule ActionsTest do
  use ExUnit.Case

  defmodule ActionsModel do
    use OCCI.Model

    kind "http://example.org/occi#compute",
      alias: Compute,
      parent: "http://schemas.ogf.org/occi/core#resource",
      attributes: [
	      status: [default: :active, type: [:active, :inactive]]
      ] do

      action stop(entity, attrs),
	      title: "Stop the compute entity",
	      attributes: [
	        method: [type: [:kill, :term], required: true],
	        reason: [type: OCCI.Types.String]
	      ] do
	      set(entity, :status, :inactive)
      end

      action action0(entity, attrs),
	      title: "An action",
	      category: "http://example.org/an/arbitrary/name#action0" do
	      entity
      end
    end
  end

  test "Launch action" do
    res = ActionsModel.new("http://example.org/occi#compute", %{ id: "/an_id" })
    assert match?(:inactive,
      ActionsModel.Compute.get(ActionsModel.Compute.stop(res, %{ method: :term }), :status))

    assert_raise OCCI.Error, fn ->
      ActionsModel.Compute.stop(res, %{})
    end
  end
end
