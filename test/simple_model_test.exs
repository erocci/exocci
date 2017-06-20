defmodule SimpleModelTest do
  use ExUnit.Case

  defmodule SimpleModel do
    require OCCI.Model.Core
    use OCCI.Model
    
    kind "http://example.org/occi/simple#mykind0",
      parent: OCCI.Model.Core.kind_resource
    
    kind "http://example.org/occi/simple#mykindlink0",
      parent: OCCI.Model.Core.kind_link
    
    mixin "http://example.org/occi/simple#mymixin0"
  end
  
  test "Creates model" do
    assert :"http://example.org/occi/simple#mykind0" in SimpleModel.kinds()
    assert :"http://example.org/occi/simple#mykindlink0" in SimpleModel.kinds()

    assert :"http://example.org/occi/simple#mymixin0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins()) == 1
  end

  test "Updates model" do
    SimpleModel.mixin("http://example.org/occi#mytag0")
    assert :"http://example.org/occi#mytag0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins) == 2

    SimpleModel.del_mixin("http://example.org/occi#mytag0")
    assert not :"http://example.org/occi#mytag0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins) == 1    
  end

  test "Creates Kind module" do
    assert match?({:module, :"http://example.org/occi/simple#mykind0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mykind0"))
   
    assert match?({:module, :"http://example.org/occi/simple#mykindlink0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mykindlink0"))

    assert match?(:"http://example.org/occi/simple#", :"http://example.org/occi/simple#mykind0".scheme)
    assert match?(:mykind0, :"http://example.org/occi/simple#mykind0".term)
  end

  test "Creates Mixin module" do
    assert match?({:module, :"http://example.org/occi/simple#mymixin0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mymixin0"))

    assert match?(:"http://example.org/occi/simple#", :"http://example.org/occi/simple#mymixin0".scheme)
    assert match?(:mymixin0, :"http://example.org/occi/simple#mymixin0".term)
end
end
