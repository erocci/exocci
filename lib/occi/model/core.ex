defmodule OCCI.Model.Core do
  use OCCI.Model,
    core: false

  kind "http://schemas.ogf.org/occi/core#entity",
    alias: Entity

  kind "http://schemas.ogf.org/occi/core#resource",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Resource
  
  kind "http://schemas.ogf.org/occi/core#link",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Link
end
