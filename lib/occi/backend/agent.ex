defmodule OCCI.Backend.Agent do
  @moduledoc """
  Agent based backend
  """
  use OCCI.Backend
  require OCCI.Node

  @doc false
  def init([src]) do
    path = case src do
             {:priv_dir, path} ->
               Path.join(:code.priv_dir(:mingus), path)
             p when is_binary(p) ->
               p
           end
    model = Application.get_env(:occi, :model, OCCI.Model.Core)
    data = File.read!(path) |> Poison.decode!(keys: :atoms) |> parse(model)
    {:ok, data}
  end

  @doc false
  def fetch(location, state) do
    {:reply, Map.get(state, location), state}
  end

  @doc false
  def store(node, state) do
    state = Map.put(state, OCCI.Node.node(node, :location), node)
    {:reply, node, state}
  end

  @doc false
  def lookup(filter, state) do
    ret = state |>
      Enum.filter(fn ({_, n}) -> OCCI.Filter.match(OCCI.Node.node(n, :data), filter) end) |>
      Enum.map(&(elem(&1, 2)))
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
    Enum.reduce(data, %{}, fn (item, store) ->
      OCCI.Rendering.JSON.parse(model, item) |>
      (&(OCCI.Node.node(location: &1.id, data: &1))).() |>
      (&(Map.put(store, OCCI.Node.node(&1, :location), &1))).()
    end)
  end
end
