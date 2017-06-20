defmodule SimpleModelTest do
  use ExUnit.Case

  defmodule SimpleModel do
    use OCCI.Model
    
    kind "http://example.org/occi/simple#mykind0",
      parent: OCCI.Model.Core.Resource
    
    kind "http://example.org/occi/simple#mykindlink0",
      parent: OCCI.Model.Core.Link
    
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
end
