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

      action action0(entity, %{ reason: reason }),
	      title: "An action",
	      attributes: [
	        reason: [type: OCCI.Types.String]
	      ] do
	      set(entity, :attr0, reason)
      end

      action action1

      action action2,
        title: "An action with options"
    end

    # mixin Mixin0,
    #   title: "A mixin"
    #   do
    #   action stop(entity, _attrs) do
    #     OCCI.Model.Core.Entity.set(entity, :status, :schrodinger)
    #   end
    # end
  end

  # defmodule ActionsModel2 do
  #   use OCCI.Model,
  #     scheme: "http://example.org/occi2#"

  #   extends ActionsModel

  #   # action :'http://example.org/occi/compute/action#stop'.(entity, %{ method: method }) do
  #   #   OCCI.Model.Core.Entity.set(entity, :killed, true)
  #   # end
  # end

  test "Action syntax" do
    assert_raise RuntimeError, "Action 'action0' defines body, signature expects 2 arguments.", fn ->
      defmodule TestModel0 do
        use OCCI.Model,
          scheme: "http://example.org/model0"

        kind Kind1,
          parent: OCCI.Model.Core.Resource do
          action action0,
            title: "A title",
            do: :ok
        end
      end
    end

    assert_raise RuntimeError, "Action 'action0' defines body, signature expects 2 arguments.", fn ->
      defmodule TestModel1 do
        use OCCI.Model,
          scheme: "http://example.org/model0"

        kind Kind2,
          parent: OCCI.Model.Core.Resource do
          action action0,
            title: "A title"
            do
            :ok
          end
        end
      end
    end

    assert_raise RuntimeError, "Action 'action0' defines body as keyword and as 'do' block.", fn ->
      defmodule TestModel2 do
        use OCCI.Model,
          scheme: "http://example.org/model0"

        kind Kind2,
          parent: OCCI.Model.Core.Resource do
          action action0,
            title: "A title",
            do: :ok
            do
            :ok
          end
        end
      end
    end
  end

  # test "Launch action" do
  #   res = ActionsModel.Kind0.new(%{ id: "/an_id" })
  #   assert match?("personal reason",
  #     Core.Entity.get(ActionsModel.Compute.action0(res, %{ reason: "personal reason" }), :attr0))
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
