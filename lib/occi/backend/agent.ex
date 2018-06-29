defmodule OCCI.Backend.Agent do
  @moduledoc """
  Agent based backend
  """
  use OCCI.Backend
  alias OCCI.Model.Core.Entity

  @doc false
  def init([src]) do
    path =
      case src do
        {:priv_dir, path} ->
          Path.join(:code.priv_dir(:mingus), path)

        p when is_binary(p) ->
          p
      end

    model = Application.get_env(:occi, :model, OCCI.Model.Core)
    data = path |> File.read!() |> Poison.decode!(keys: :atoms) |> parse(model)
    {:ok, data}
  end

  @doc false
  def fetch(location, state) do
    {:reply, Map.get(state, location), state}
  end

  @doc false
  def store(entity, state) do
    state = Map.put(state, Entity.get(entity, :location), entity)
    {:reply, entity, state}
  end

  @doc false
  def lookup(filter, state) do
    ret =
      state
      |> Enum.filter(fn {_, entity} -> OCCI.Filter.match(entity, filter) end)
      |> Enum.map(&elem(&1, 1))

    {:reply, ret, state}
  end

  @doc false
  def delete(location, state) do
    state = Map.delete(state, location)
    {:reply, :ok, state}
  end

  ###
  ### Private
  ###
  defp parse(data, model) do
    Enum.reduce(data, %{}, fn item, store ->
      model
      |> OCCI.Rendering.JSON.parse(item)
      |> (&Map.put(store, Entity.location(&1), &1)).()
    end)
  end
end
