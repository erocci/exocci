defmodule OCCI.Store do
  @moduledoc """
  OCCI datastore entry point

  OCCI entities are stored in backends (see `OCCI.Backend`). Backend
  must be declared in `:occi` env, for instance:
  ```
  config :occi, backend: {OCCI.Backend.Agent, priv_dir: "data.json"}
  ```
  """

  alias OCCI.Model.Core.Entity
  require Logger

  @doc false
  def child_spec(args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [args]}}
  end

  @doc """
  Start Store with given backends
  """
  def start_link({mod, args}) do
    case mod.init(args) do
      {:ok, state0} -> Agent.start_link(fn -> {mod, state0} end, name: __MODULE__)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get an node by location
  """
  @spec get(Entity.location()) :: Core.Entity.t() | nil
  def get(location) do
    Logger.debug(fn -> "Store.get(#{location})" end)
    call(:fetch, [location])
  end

  @doc """
  Lookup entities
  """
  @spec lookup([OCCI.Filter.t()]) :: [Entity.t()]
  def lookup(filter) do
    Logger.debug(fn -> "Store.lookup(#{inspect(filter)})" end)
    call(:lookup, [filter])
  end

  @doc """
  Save entity
  """
  @spec create(Entity.t(), Entity.owner()) :: Core.Entity.t()
  def create(entity, location \\ nil, owner \\ nil) do
    Logger.debug(fn -> "Store.create(#{inspect(entity)})" end)

    location =
      if location do
        case call(:fetch, [location]) do
          nil -> location
          _ -> raise OCCI.Error, 409
        end
      else
        UUID.uuid4()
      end

    call(:store, [Entity.attributes(entity, %{location: location, owner: owner, serial: 0})])
  end

  @doc """
  Update given entity
  """
  @spec update(Entity.t()) :: Entity.t()
  def update(entity) do
    Logger.debug(fn -> "Store.update(#{inspect(entity)})" end)

    case call(:fetch, Entity.location(entity)) do
      nil -> raise OCCI.Error, 404
      orig -> call(:store, [Entity.node(entity, Entity.node(orig))])
    end
  end

  @doc """
  Delete entity
  """
  @spec delete(OCCI.Node.location()) :: boolean
  def delete(location) do
    Logger.debug(fn -> "Store.delete(#{location})" end)

    case call(:fetch, location) do
      nil -> raise OCCI.Error, 404
      _ -> call(:delete, [location])
    end
  end

  ###
  ### Private
  ###
  defp call(name, args) do
    Agent.get_and_update(__MODULE__, fn {mod, state0} ->
      case apply(mod, name, args ++ [state0]) do
        {:reply, ret, state} ->
          {ret, {mod, state}}

        {:stop, reason, state} ->
          try do
            mod.terminate(:shutdown, state)
          rescue
            _ -> :ok
          end

          raise OCCI.Error, {mod, state, reason}
      end
    end)
  end
end
