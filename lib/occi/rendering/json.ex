defmodule OCCI.Rendering.JSON do
  @moduledoc """
  JSON parser / renderer
  """
  alias OCCI.Model.Core

  @doc false
  def parse(model, data) when is_map(data) do
    kind = Map.get_lazy(data, :kind, fn -> raise OCCI.Error, {422, "Missing attribute: kind"} end)

    mixins =
      data
      |> Map.get(:mixins, [])
      |> Enum.map(fn mixin ->
        case model.module(mixin) do
          nil -> raise OCCI.Error, {422, "Invalid category: #{mixin}"}
          mod -> mod
        end
      end)

    case model.module(kind) do
      nil -> raise OCCI.Error, {422, "Invalid category: #{kind}"}
      mod -> mod.new(data, mixins, __MODULE__)
    end
  end

  def parse(model, data) when is_binary(data) do
    parse(model, Poison.decode!(data, keys: :atoms!))
  end

  @doc false
  def render(entity) do
    entity
    |> Core.Entity.print()
    |> Poison.encode!(pretty: true)
  end
end

defimpl Poison.Decoder, for: Atom do
  def decode(value, _opts) do
    IO.puts("DECODE: #{value}")
    value
  end
end
