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

  test "Using model macro" do
    assert :"http://example.org/occi/simple#mykind0" in SimpleModel.kinds()
    assert :"http://example.org/occi/simple#mykindlink0" in SimpleModel.kinds()

    assert :"http://example.org/occi/simple#mymixin0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins()) == 1

    SimpleModel.mixin("http://example.org/occi#mytag0")
    assert :"http://example.org/occi#mytag0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins) == 2

    SimpleModel.del_mixin("http://example.org/occi#mytag0")
    assert not :"http://example.org/occi#mytag0" in SimpleModel.mixins()
    assert MapSet.size(SimpleModel.mixins) == 1    
  end

  test "kind macro" do
    assert match?({:module, :"http://example.org/occi/simple#mykind0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mykind0"))
    
    assert match?({:module, :"http://example.org/occi/simple#mykindlink0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mykindlink0"))    
  end
end
