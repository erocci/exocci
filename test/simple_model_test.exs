defmodule SimpleModelTest do
  use ExUnit.Case

  defmodule SimpleModel do
    use OCCI.Model
    
    kind "http://example.org/occi/simple#mykind0",
      parent: OCCI.Model.Core.Resource
    
    kind "http://example.org/occi/simple#mykindlink0",
      parent: OCCI.Model.Core.Link,
      title: "My link category"
    
    mixin "http://example.org/occi/simple#mymixin0"
  end
  
  test "Creates model" do
    assert SimpleModel.kind?(:"http://example.org/occi/simple#mykind0") 
    assert SimpleModel.kind?(:"http://example.org/occi/simple#mykindlink0")

    assert SimpleModel.mixin?(:"http://example.org/occi/simple#mymixin0")
    assert Map.size(SimpleModel.mixins()) == 1
  end

  test "Updates model" do
    SimpleModel.mixin("http://example.org/occi#mytag0")
    assert SimpleModel.mixin?(:"http://example.org/occi#mytag0")
    assert Map.size(SimpleModel.mixins) == 2

    SimpleModel.del_mixin("http://example.org/occi#mytag0")
    assert not SimpleModel.mixin?(:"http://example.org/occi#mytag0")
    assert Map.size(SimpleModel.mixins) == 1    
  end

  test "Creates Kind module" do
    modname = SimpleModel.mod(:"http://example.org/occi/simple#mykind0")
    assert match?({:module, modname}, Code.ensure_loaded(modname))

    modname = SimpleModel.mod(:"http://example.org/occi/simple#mykindlink0")
    assert match?({:module, modname}, Code.ensure_loaded(modname))

    assert match?(:"http://example.org/occi/simple#",
      SimpleModel.mod(:"http://example.org/occi/simple#mykind0").scheme)
    assert match?(:mykind0,
      SimpleModel.mod(:"http://example.org/occi/simple#mykind0").term)
  end

  test "Creates Mixin module" do
    modname = SimpleModel.mod(:"http://example.org/occi/simple#mymixin0")
    assert match?({:module, modname}, Code.ensure_loaded(modname))
    
    assert match?(:"http://example.org/occi/simple#",
      SimpleModel.mod(:"http://example.org/occi/simple#mymixin0").scheme)
    assert match?(:mymixin0,
      SimpleModel.mod(:"http://example.org/occi/simple#mymixin0").term)
  end

  test "Check title" do
    # Default kind title
    assert match?("Kind http://example.org/occi/simple#mykind0",
      SimpleModel.mod("http://example.org/occi/simple#mykind0").title())

    # Default mixin title
    assert match?("Mixin http://example.org/occi/simple#mymixin0",
      SimpleModel.mod("http://example.org/occi/simple#mymixin0").title())

    # Custom title
    assert match?("My link category",
      SimpleModel.mod("http://example.org/occi/simple#mykindlink0").title())
  end
end
