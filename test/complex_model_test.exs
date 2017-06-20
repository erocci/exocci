defmodule ComplexModelTest do
  use ExUnit.Case

  defmodule ComplexModel do
    use OCCI.Model

    kind "http://example.org/occi/complex#mykind0",
      parent: OCCI.Model.Core.Resource
    
    kind "http://example.org/occi/complex#mykind1",
      parent: "http://example.org/occi/complex#mykind0"
  end
  
  test "Creates model" do
    assert ComplexModel.kind?(:"http://example.org/occi/complex#mykind0")
    assert ComplexModel.kind?(:"http://example.org/occi/complex#mykind1")
  end

  test "Check parents" do
    assert match?([
      :"http://example.org/occi/complex#mykind0",
      :"http://schemas.ogf.org/occi/core#resource",
      :"http://schemas.ogf.org/occi/core#entity"
    ], ComplexModel.mod(:"http://example.org/occi/complex#mykind1").parent!())
  end
end
