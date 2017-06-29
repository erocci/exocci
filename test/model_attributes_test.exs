defmodule ModelAttributesTest do
  use ExUnit.Case

  test "Check Core attributes" do
    assert match?(
      %{ id: "/an_id", attributes: %{ title: "A title" } },
      OCCI.Model.Core.Resource.new(%{ id: "/an_id", title: "A title" })
    )

    assert_raise OCCI.Error, "Undefined attribute: unknown.attribute",
    fn ->
      OCCI.Model.Core.Resource.new(%{ id: "/an_id", "unknown.attribute": "a value" })
    end
  end
end
