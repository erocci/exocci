defmodule ModelAttributesTest do
  use ExUnit.Case

  test "Check Core attributes" do
    assert match?(
             %{id: "/an_id", attributes: %{"occi.core.title": "A title"}},
             OCCI.Model.Core.Resource.new(%{id: "/an_id", "occi.core.title": "A title"})
           )

    assert_raise OCCI.Error, "Undefined attribute: unknown.attribute", fn ->
      OCCI.Model.Core.Resource.new(%{id: "/an_id", "unknown.attribute": "a value"})
    end
  end

  test "Attribute alias" do
    assert match?(
             %{id: "/an_id", attributes: %{"occi.core.title": "A title"}},
             OCCI.Model.Core.Resource.new(%{id: "/an_id", title: "A title"})
           )

    assert match?(
             "A title",
             OCCI.Model.Core.Entity.get(
               %{
                 kind: OCCI.Model.Core.Resource,
                 attributes: %{"occi.core.title": "A title"},
                 __node__: %{model: OCCI.Model.Core}
               },
               :title
             )
           )
  end

  test "Required attributes" do
    assert_raise OCCI.Error, "Missing attributes: id", fn ->
      OCCI.Model.Core.Resource.new(%{title: "A title"})
    end
  end

  defmodule ModelAttributesModel do
    use OCCI.Model,
      scheme: "http://example.org/occi"

    alias OCCI.Model.Core

    kind(
      Kind0,
      parent: Core.Resource,
      attributes: [
        attr0: [default: 10, type: OCCI.Types.Integer],
        attr1: [type: [:un, :deux, :trois]]
      ]
    )

    mixin Mixin0 do
      attribute(
        "attr0",
        default: 11,
        type: OCCI.Types.Integer
      )
    end

    mixin Mixin1 do
      attribute(
        "attr0",
        default: 12,
        type: OCCI.Types.Integer
      )
    end

    mixin(
      Mixin2,
      depends: [Mixin1]
    )
  end

  test "Enum attributes" do
    assert match?(
             %{attributes: %{attr1: :trois}},
             ModelAttributesModel.Kind0.new(%{id: "/an_id", attr1: :trois})
           )

    assert_raise OCCI.Error, ~r/^Invalid value:.*$/, fn ->
      ModelAttributesModel.Kind0.new(%{id: "/an_id", attr1: :quatre})
    end
  end

  test "Default attribute values" do
    res = ModelAttributesModel.Kind0.new(%{id: "/an_id"})
    assert match?(10, OCCI.Model.Core.Resource.get(res, "attr0"))
  end

  test "Default value with(out) mixins" do
    # Default value without mixin
    res = ModelAttributesModel.Kind0.new(%{id: "/an_id"})
    assert match?(10, OCCI.Model.Core.Resource.get(res, "attr0"))

    # Default value with mixin
    res = OCCI.Model.Core.Entity.add_mixin(res, ModelAttributesModel.Mixin0)
    assert match?(11, OCCI.Model.Core.Resource.get(res, "attr0"))

    # Default value with mixin deps
    res = OCCI.Model.Core.Entity.add_mixin(res, ModelAttributesModel.Mixin2)
    assert match?(12, OCCI.Model.Core.Resource.get(res, "attr0"))
  end
end
