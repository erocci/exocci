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
end
