defmodule ComplexModelTest do
  use ExUnit.Case

  defmodule ComplexModel do
    use OCCI.Model,
      scheme: "http://example.org/occi/complex"

    alias OCCI.Model.Core

    kind(
      MyKind0,
      parent: Core.Resource
    )

    kind(
      MyKind1,
      parent: MyKind0
    )

    kind(MyKind2)

    mixin(MyMixin0)

    mixin(MyMixin1)

    mixin(MyMixin2)

    mixin(
      MyMixin10,
      depends: [MyMixin0, MyMixin1]
    )

    mixin(
      MyMixin11,
      depends: [MyMixin10]
    )

    mixin(
      MyMixin12,
      depends: [
        MyMixin10,
        MyMixin0,
        MyMixin2
      ]
    )

    mixin(
      MyMixin20,
      applies: [MyKind1]
    )
  end

  alias OCCI.Model.Core

  test "Creates model" do
    assert ComplexModel.kind?(ComplexModel.MyKind0)
    assert ComplexModel.kind?(ComplexModel.MyKind1)

    assert ComplexModel.mixin?(ComplexModel.MyMixin0)
    assert ComplexModel.mixin?(ComplexModel.MyMixin1)
    assert ComplexModel.mixin?(ComplexModel.MyMixin10)
  end

  test "Check parents" do
    assert match?(
             [
               ComplexModel.MyKind0,
               Core.Resource,
               Core.Entity
             ],
             ComplexModel.MyKind1.parent!()
           )
  end

  test "Check mixin simple depends" do
    assert match?(
             [
               ComplexModel.MyMixin0,
               ComplexModel.MyMixin1
             ],
             ComplexModel.MyMixin10.depends!()
           )
  end

  test "Check mixin transitive depends" do
    assert match?(
             [
               ComplexModel.MyMixin10,
               ComplexModel.MyMixin0,
               ComplexModel.MyMixin1
             ],
             ComplexModel.MyMixin11.depends!()
           )
  end

  test "Check mixin complex depends" do
    assert match?(
             [
               ComplexModel.MyMixin10,
               ComplexModel.MyMixin0,
               ComplexModel.MyMixin1,
               ComplexModel.MyMixin2
             ],
             ComplexModel.MyMixin12.depends!()
           )
  end

  test "Check mixin applies" do
    assert ComplexModel.MyMixin20.apply?(ComplexModel.MyKind1)
    assert ComplexModel.MyMixin20.apply?(ComplexModel.MyKind0)

    assert not ComplexModel.MyMixin20.apply?(ComplexModel.MyKind2)
  end

  test "Check entity categories" do
    assert match?(
             [
               ComplexModel.MyKind0,
               Core.Resource,
               Core.Entity
             ],
             ComplexModel.MyKind0.categories(%{
               kind: ComplexModel.MyKind0,
               mixins: [],
               __node__: %{model: ComplexModel}
             })
           )

    assert match?(
             [
               ComplexModel.MyMixin1,
               ComplexModel.MyMixin12,
               ComplexModel.MyMixin10,
               ComplexModel.MyMixin0,
               ComplexModel.MyMixin2,
               ComplexModel.MyKind0,
               Core.Resource,
               Core.Entity
             ],
             ComplexModel.MyKind0.categories(%{
               kind: ComplexModel.MyKind0,
               mixins: [ComplexModel.MyMixin1, ComplexModel.MyMixin12],
               __node__: %{model: ComplexModel}
             })
           )
  end
end
