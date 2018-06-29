defmodule OCCI.Model.Core do
  @moduledoc """
  Declaration of OCCI Core model: `Entity`, `Resource`, `Link`

  See [https://www.ogf.org/documents/GFD.221.pdf]
  """
  use OCCI.Model,
    core: false,
    scheme: "http://schemas.ogf.org/occi/core"

  alias OCCI.Types

  require Types.String

  kind Entity do
    alias OCCI.Model.Core.Entity

    @type location :: String.t()
    @type owner :: {String.t(), String.t()} | nil
    @type t :: %{}

    attribute(
      :kind,
      get: &Entity.kind/1
    )

    attribute(
      :mixins,
      get: &Entity.mixins/1,
      set: &Entity.mixins/2
    )

    attribute(
      :id,
      alias: "occi.core.id",
      required: true,
      get: &Entity.id/1,
      set: &Entity.id/2
    )

    attribute(
      "occi.core.title",
      alias: :title,
      type: Types.String
    )

    attribute(
      :attributes,
      get: &Entity.attributes/1,
      set: &Entity.attributes/2
    )

    attribute(
      :location,
      get: &Entity.location/1,
      set: &Entity.location/2
    )

    attribute(
      :owner,
      get: &Entity.owner/1,
      set: &Entity.owner/2
    )

    attribute(
      :serial,
      get: &Entity.serial/1,
      set: &Entity.serial/2
    )

    attribute(
      :model,
      get: &Entity.__model__/1
    )

    attribute(
      :node,
      get: &Entity.node/1,
      set: &Entity.node/2
    )

    def id(entity), do: entity.id
    def id(entity, value), do: Map.put(entity, :id, Types.URI.cast(value))

    def kind(entity), do: entity.kind

    def mixins(entity), do: Map.get(entity, :mixins, [])
    def mixins(entity, mixins), do: Map.put(entity, :mixins, mixins)

    def attributes(entity), do: Map.get(entity, :attributes, %{})

    def attributes(entity, attrs) do
      attrs |> Enum.reduce(entity, fn {k, v}, acc -> set(acc, k, v) end)
    end

    def location(entity), do: entity.__node__.location || entity.id

    def location(entity, location) do
      Map.put(entity, :__node__, %{entity.__node__ | location: Types.URI.cast(location)})
    end

    def owner(entity), do: entity.__node__.owner

    def owner(entity, {_, _} = owner) do
      Map.put(entity, :__node__, %{entity.__node__ | owner: owner})
    end

    def owner(entity, nil) do
      Map.put(entity, :__node__, %{entity.__node__ | owner: nil})
    end

    def serial(entity), do: entity.__node__.serial

    def serial(entity, serial) do
      Map.put(entity, :__node__, %{entity.__node__ | serial: serial})
    end

    @doc false
    def __model__(entity), do: entity.__node__.model

    def node(entity), do: entity.__node__
    def node(entity, node), do: %{entity | __node__: node}

    def add_mixin(entity, mixin) do
      Map.put(entity, :mixins, [:"#{mixin}" | Map.get(entity, :mixins, [])])
    end

    def rm_mixin(entity, mixin) do
      Map.put(entity, :mixins, List.delete(Map.get(entity, :mixins, []), :"#{mixin}"))
    end

    @doc """
    Return printable version: remove __node__ attribute, add default value
    of required attributes when not defined
    """
    def print(entity) do
      model = entity.__node__.created_in

      defaults =
        [entity.kind | entity.mixins]
        |> model.required()
        |> Enum.reduce(%{}, fn key, acc -> Map.put(acc, key, get(entity, key)) end)

      entity
      |> Map.put(:attributes, Map.merge(defaults, entity.attributes))
      |> Map.drop([:__node__])
    end
  end

  kind Resource,
    parent: Entity do
    attribute(
      "occi.core.summary",
      alias: :summary,
      type: Types.String
    )

    attribute(
      :links,
      get: &Resource.links/1,
      set: &Resource.links/2
    )

    def links(resource) do
      Map.get(resource, :links, [])
    end

    def links(resource, links) when is_list(links) do
      Map.put(resource, :links, Enum.map(links, &Types.URI.cast/1))
    end

    defdelegate add_mixin(entity, mixin), to: Entity
    defdelegate rm_mixin(entity, mixin), to: Entity
  end

  kind Link,
    parent: Entity do
    alias OCCI.Model.Core.Entity

    attribute(
      :source,
      required: true,
      get: &Link.source/1,
      set: &Link.source/2
    )

    attribute(
      :target,
      required: true,
      get: &Link.target/1,
      set: &Link.target/2
    )

    attribute(
      :target_kind,
      get: &Link.target_kind/1,
      set: &Link.target_kind/2
    )

    def source(link), do: link |> Map.get(:source, %{}) |> Map.get(:location, nil)

    def source(link, uri) do
      src = Map.get(link, :source, %{})
      Map.put(link, :source, Map.put(src, :location, Types.URI.cast(uri)))
    end

    def target(link), do: link |> Map.get(:target, %{}) |> Map.get(:location, nil)

    def target(link, uri) do
      target = Map.get(link, :target, %{})
      Map.put(link, :target, Map.put(target, :location, Types.URI.cast(uri)))
    end

    def target_kind(link), do: get_in(link, [:target, :kind])

    def target_kind(link, kind) do
      target = Map.get(link, :target, %{})
      model = Entity.__model__(link) || @model
      casted = Types.Kind.cast(kind, model)
      Map.put(link, :target, Map.put(target, :kind, casted))
    end

    defdelegate add_mixin(entity, mixin), to: Entity
    defdelegate rm_mixin(entity, mixin), to: Entity
  end
end
