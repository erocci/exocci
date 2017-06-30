defmodule ModelAttributesTest do
  use ExUnit.Case
  
  test "Check Core attributes" do
    assert match?(
      %{ id: "/an_id", attributes: %{ "occi.core.title": "A title" } },
      OCCI.Model.Core.Resource.new(%{ id: "/an_id", "occi.core.title": "A title" })
    )

    assert_raise OCCI.Error, "Undefined attribute: unknown.attribute",
    fn ->
      OCCI.Model.Core.Resource.new(%{ id: "/an_id", "unknown.attribute": "a value" })
    end
  end

  test "Attribute alias" do
    assert match?(
      %{ id: "/an_id", attributes: %{ "occi.core.title": "A title" } },
      OCCI.Model.Core.Resource.new(%{ id: "/an_id", title: "A title" })
    )

    assert match?("A title",
      OCCI.Model.Core.Entity.get(%{ kind: :"http://schemas.ogf.org/occi/core#resource",
				    attributes: %{ "occi.core.title": "A title" } }, :title))
  end

  test "Required attributes" do
    assert_raise OCCI.Error, "Missing attributes: id",
    fn ->
      OCCI.Model.Core.Resource.new(%{ title: "A title" })
    end
  end

  defmodule TestModel do
    use OCCI.Model

    kind "http://example.org/occi#kind0",
      parent: "http://schemas.ogf.org/occi/core#resource" do
      attribute "attr0",
	default: 10,
	type: OCCI.Types.Integer
    end
  end

  test "Default attribute values" do
    res = TestModel.new("http://example.org/occi#kind0", %{ id: "/an_id" })
    assert match?(10, OCCI.Model.Core.Resource.get(res, "attr0"))
  end
end
