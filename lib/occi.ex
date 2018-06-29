defmodule OCCI do
  @moduledoc """
  OCCI is a resource oriented meta-model.

  In a few words, if you care about strongly typed resources for REST
  API, it is for you.

  The OCCI meta-model is described in various documents:
  * [OCCI Core specifications](http://ogf.org/documents/GFD.221.pdf)
  * [OCCI-wg website](http://occi-wg.org/about/specification/): HTTP
    renderings, standardized models,e tc

  Thanks to the elixir language, OCCI models are described thanks to a
  DSL. Then:
  * Categories are mapped to modules;
  * Entities implements `Access` protocol, and can be manipulated as
    maps, but with type checking (and casting);

  Model example is provided in `OCCI.Model.Infrastructure`.
  """
end
