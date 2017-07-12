defmodule JsonTest do
  use ExUnit.Case

  test "Parse JSON" do
    assert match?(%{
          kind: :"http://schemas.ogf.org/occi/core#resource",
          id: "/my/id",
          links: [
            "/a/link"
          ],
          attributes: %{
            "occi.core.summary": "A summary"
          }
                  },
      OCCI.Rendering.JSON.parse(OCCI.Model.Core,
        "{ \"id\": \"/my/id\", \"kind\": \"http://schemas.ogf.org/occi/core#resource\", \"links\": [ \"/a/link\" ], \"attributes\": { \"occi.core.summary\": \"A summary\" } }"))
  end
end
