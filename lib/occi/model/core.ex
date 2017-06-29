defmodule OCCI.Model.Core do
  use OCCI.Model,
    core: false

  kind "http://schemas.ogf.org/occi/core#entity", alias: Entity do
    attribute :id,
      alias: :"occi.core.id",
      get: &OCCI.Model.Core.Entity.id/1,
      set: &OCCI.Model.Core.Entity.id/2

    attribute :title,
      alias: :"occi.core.title",
      type: OCCI.Types.String
      
    def id(entity), do: entity.id
    def id(entity, value), do: Map.put(entity, :id, OCCI.Types.URI.cast(value))
  end

  kind "http://schemas.ogf.org/occi/core#resource",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Resource do
  end
  
  kind "http://schemas.ogf.org/occi/core#link",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Link do
  end
end
