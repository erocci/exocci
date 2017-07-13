defmodule OCCI.Model.Core do
  use OCCI.Model,
    core: false

  kind "http://schemas.ogf.org/occi/core#entity", alias: Entity do
    attribute :kind,
      get: &OCCI.Model.Core.Entity.kind/1

    attribute :mixins,
      get: &OCCI.Model.Core.Entity.mixins/1,
      set: &OCCI.Model.Core.Entity.mixins/2

    attribute :id,
      alias: "occi.core.id",
      required: true,
      get: &OCCI.Model.Core.Entity.id/1,
      set: &OCCI.Model.Core.Entity.id/2

    attribute "occi.core.title",
      alias: :title,
      type: OCCI.Types.String

    attribute :attributes,
      get: &OCCI.Model.Core.Entity.attributes/1,
      set: &OCCI.Model.Core.Entity.attributes/2

    def id(entity), do: entity.id
    def id(entity, value), do: Map.put(entity, :id, OCCI.Types.URI.cast(value))

    def kind(entity), do: entity.kind

    def mixins(entity), do: Map.get(entity, :mixins, [])
    def mixins(entity, mixins), do: Map.put(entity, :mixins, mixins)

    def attributes(entity), do: Map.get(entity, :attributes, %{})
    def attributes(entity, attrs) do
      attrs |> Enum.reduce(entity, fn {k, v}, acc -> set(acc, k, v) end)
    end

    def add_mixin(entity, mixin) do
      Map.put(entity, :mixins, [ :"#{mixin}" | Map.get(entity, :mixins, []) ])
    end

    def rm_mixin(entity, mixin) do
      Map.put(entity, :mixins, List.delete(Map.get(entity, :mixins, []), :"#{mixin}"))
    end
  end

  kind "http://schemas.ogf.org/occi/core#resource",
    parent: "http://schemas.ogf.org/occi/core#entity",
    alias: Resource do

    attribute "occi.core.summary",
      alias: :summary,
      type: OCCI.Types.String

    attribute :links,
      get: &OCCI.Model.Core.Resource.links/1,
      set: &OCCI.Model.Core.Resource.links/2

    def links(resource) do
      Map.get(resource, :links, [])
    end

    def links(resource, links) when is_list(links) do
      Map.put(resource, :links, Enum.map(links, &OCCI.Types.URI.cast/1))
    end

    defdelegate add_mixin(entity, mixin), to: Entity
    defdelegate rm_mixin(entity, mixin), to: Entity
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

    attribute :target_kind,
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
      casted = OCCI.Types.Kind.cast(kind, get_in(link, [:__internal__, :model]) || @model)
      Map.put(link, :target, Map.put(target, :kind, casted))
    end

    defdelegate add_mixin(entity, mixin), to: Entity
    defdelegate rm_mixin(entity, mixin), to: Entity
  end
end
