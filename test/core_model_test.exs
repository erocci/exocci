defmodule CoreModelTest do
  use ExUnit.Case

  test "Check entity instanciation" do
    # Entity is abstract, can not be instantiated
    assert_raise UndefinedFunctionError, fn ->
      OCCI.Model.Core.Entity.new()
    end
  end

  test "Check resource instanciation" do
    assert match?(%{ kind: OCCI.Model.Core.Resource }, OCCI.Model.Core.Resource.new(%{ id: "an id"}))
  end

  test "Check link instanciation" do
    assert match?(%{ kind: OCCI.Model.Core.Link },
      OCCI.Model.Core.Link.new(%{ id: "an id", source: "/source", target: "/target" }))
  end
end
