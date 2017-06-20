defmodule ComplexModelTest do
  use ExUnit.Case

  defmodule ComplexModel do
    use OCCI.Model

    kind "http://example.org/occi/complex#mykind0",
      parent: OCCI.Model.Core.Resource
    
    kind "http://example.org/occi/complex#mykind1",
      parent: "http://example.org/occi/complex#mykind0"

    mixin "http://example.org/occi/complex#mymixin0"

    mixin "http://example.org/occi/complex#mymixin1"
    
    mixin "http://example.org/occi/complex#mymixin2"

    mixin "http://example.org/occi/complex#mymixin10",
      depends: ["http://example.org/occi/complex#mymixin0", "http://example.org/occi/complex#mymixin1"]

    mixin "http://example.org/occi/complex#mymixin11",
      depends: ["http://example.org/occi/complex#mymixin10"]

    mixin "http://example.org/occi/complex#mymixin12",
      depends: [
	"http://example.org/occi/complex#mymixin10",
	"http://example.org/occi/complex#mymixin0",
	"http://example.org/occi/complex#mymixin2"
      ]
end
  
  test "Creates model" do
    assert ComplexModel.kind?(:"http://example.org/occi/complex#mykind0")
    assert ComplexModel.kind?(:"http://example.org/occi/complex#mykind1")

    assert ComplexModel.mixin?(:"http://example.org/occi/complex#mymixin0")
    assert ComplexModel.mixin?(:"http://example.org/occi/complex#mymixin1")
    assert ComplexModel.mixin?(:"http://example.org/occi/complex#mymixin10")
  end

  test "Check parents" do
    assert match?([
      :"http://example.org/occi/complex#mykind0",
      :"http://schemas.ogf.org/occi/core#resource",
      :"http://schemas.ogf.org/occi/core#entity"
    ], ComplexModel.mod(:"http://example.org/occi/complex#mykind1").parent!())
  end

  test "Check mixin simple depends" do
    assert match?([
      :"http://example.org/occi/complex#mymixin0",
      :"http://example.org/occi/complex#mymixin1"
    ], ComplexModel.mod(:"http://example.org/occi/complex#mymixin10").depends!())
  end

  test "Check mixin transitive depends" do
    assert match?([
      :"http://example.org/occi/complex#mymixin10",
      :"http://example.org/occi/complex#mymixin0",
      :"http://example.org/occi/complex#mymixin1"
    ], ComplexModel.mod(:"http://example.org/occi/complex#mymixin11").depends!())
  end

  test "Check mixin complex depends" do
    assert match?([
      :"http://example.org/occi/complex#mymixin10",
      :"http://example.org/occi/complex#mymixin0",
      :"http://example.org/occi/complex#mymixin1",
      :"http://example.org/occi/complex#mymixin2"      
    ], ComplexModel.mod(:"http://example.org/occi/complex#mymixin12").depends!())
  end
end
