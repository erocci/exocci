defmodule OCCI.Model.Core do
  use OCCI.Model,
    core: false

  kind "http://schemas.ogf.org/occi/core#entity", alias: Entity do
    :ok
    # Custom getter
    #attr(entity, :id), do: entity.id
    #attr(entity, :title), do: entity.attributes."occi.core.title"
    
    # Custom setters
    #attr(entity, :id, id), do: %{ entity | id: OCCI.Types.URI.cast(id) }
    #attr(%{ attributes: a }=entity, :title, title) do
    #  %{ entity | attributes: %{ a | "occi.core.title": OCCI.Types.String.cast(title) } }
    #end
  end

  kind "http://schemas.ogf.org/occi/core#resource",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Resource
  
  kind "http://schemas.ogf.org/occi/core#link",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Link
end
