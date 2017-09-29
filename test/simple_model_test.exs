defmodule SimpleModelTest do
  use ExUnit.Case

  defmodule SimpleModel do
    use OCCI.Model,
      scheme: "http://example.org/occi/simple"

    alias OCCI.Model.Core

    kind MyKind0,
      parent: Core.Resource

    kind MyKindLink0,
      parent: Core.Link,
      title: "My link category"

    mixin MyMixin0
  end

  test "Creates model" do
    assert SimpleModel.kind?(SimpleModel.MyKind0)
    assert SimpleModel.kind?(SimpleModel.MyKindLink0)

    assert SimpleModel.mixin?(SimpleModel.MyMixin0)
    assert length(SimpleModel.mixins()) == 1
  end

  test "User mixins" do
    assert match?(SimpleModelTest.SimpleModel.MyTag0, SimpleModel.add_mixin(MyTag0, "http://example.org/occi#mytag0"))
    assert SimpleModel.mixin?(SimpleModelTest.SimpleModel.MyTag0)
    assert length(SimpleModel.mixins()) == 2

    assert match?(:ok, SimpleModel.del_mixin(SimpleModelTest.SimpleModel.MyTag0))
    assert not SimpleModel.mixin?(SimpleModelTest.MyTag0)
    assert length(SimpleModel.mixins()) == 1

    assert match?(:error, SimpleModel.del_mixin(InvalidMixin))
end

  test "Creates Kind module" do
    assert match?(:"http://example.org/occi/simple#", SimpleModel.MyKind0.scheme())
    assert match?(:mykind0, SimpleModel.MyKind0.term())
  end

  test "Creates Mixin module" do
    assert match?(:"http://example.org/occi/simple#", SimpleModel.MyMixin0.scheme())
    assert match?(:mymixin0, SimpleModel.MyMixin0.term())
  end

  test "Check title" do
    # Default kind title
    assert match?("Kind http://example.org/occi/simple#mykind0", SimpleModel.MyKind0.title())

    # Default mixin title
    assert match?("Mixin http://example.org/occi/simple#mymixin0", SimpleModel.MyMixin0.title())

    # Custom title
    assert match?("My link category", SimpleModel.MyKindLink0.title())
  end
end
