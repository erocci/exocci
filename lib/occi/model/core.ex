defmodule OCCI.Model.Core do
  use OCCI.Model,
    core: false

  kind "http://schemas.ogf.org/occi/core#entity", alias: Entity do
    attribute :id,
      alias: "occi.core.id",
      required: true,
      get: &OCCI.Model.Core.Entity.id/1,
      set: &OCCI.Model.Core.Entity.id/2

    attribute "occi.core.title",
      alias: :title,
      type: OCCI.Types.String
      
    def id(entity), do: entity.id
    def id(entity, value), do: Map.put(entity, :id, OCCI.Types.URI.cast(value))
  end

  kind "http://schemas.ogf.org/occi/core#resource",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Resource do
    
    attribute "occi.core.summary",
      alias: :summary,
      type: OCCI.Types.String
  end
  
  kind "http://schemas.ogf.org/occi/core#link",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Link do

    attribute :source,
      required: true,
      get: &OCCI.Model.Core.Link.source/1,
      set: &OCCI.Model.Core.Link.source/2

    attribute :target,
      required: true,
      get: &OCCI.Model.Core.Link.target/1,
      set: &OCCI.Model.Core.Link.target/2

    attribute :target,
      get: &OCCI.Model.Core.Link.target_kind/1,
      set: &OCCI.Model.Core.Link.target_kind/2

    def source(link), do: get_in(link, [:source, :location])
    def source(link, uri) do
      src = Map.get(link, :source, %{})
      Map.put(link, :source, Map.put(src, :location, OCCI.Types.URI.cast(uri)))
    end

    def target(link), do: get_in(link, [:target, :location])
    def target(link, uri) do
      target = Map.get(link, :target, %{})
      Map.put(link, :target, Map.put(target, :location, OCCI.Types.URI.cast(uri)))
    end

    def target_kind(link), do: get_in(link, [:target, :kind])
    def target_kind(link, kind) do
      target = Map.get(link, :target, %{})
      casted = OCCI.Types.Kind.cast(get_in(link, [:__internal__, :model]) || @model, kind)
      Map.put(link, :target, Map.put(target, :kind, casted))
    end
  end
end
