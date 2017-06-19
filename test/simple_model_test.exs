defmodule SimpleModelTest do
  use ExUnit.Case

  defmodule SimpleModel do
    require OCCI.Model.Core
    use OCCI.Model

    kind "http://example.org/occi/simple#mykind0",
      parent: OCCI.Model.Core.kind_resource
  end

  test "kind macro" do
    assert match?({:module, :"http://example.org/occi/simple#mykind0"},
      Code.ensure_loaded(:"http://example.org/occi/simple#mykind0"))
  end
end
