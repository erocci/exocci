defmodule CoreModelTest do
  use ExUnit.Case

  test "Check entity instanciation" do
    # Entity is abstract, can not be instantiated
    assert_raise UndefinedFunctionError, fn ->
      OCCI.Model.Core.mod("http://schemas.ogf.org/occi/core#entity").new()
    end
  end

  test "Check resource instanciation" do
    assert match?(%{ kind: :"http://schemas.ogf.org/occi/core#resource" },
      OCCI.Model.Core.mod("http://schemas.ogf.org/occi/core#resource").new(%{ id: "an id"}))
  end

  test "Check link instanciation" do
    assert match?(%{ kind: :"http://schemas.ogf.org/occi/core#link" },
      OCCI.Model.Core.mod("http://schemas.ogf.org/occi/core#link").new(%{
	    id: "an id", source: "/source", target: "/target" }))
  end
end
