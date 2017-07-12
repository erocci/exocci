defmodule OCCI.Store do
  require Logger
  require OCCI.Node

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
  @spec get(OCCI.Node.location) :: OCCI.Node.t | nil
  def get(location) do
    Logger.debug("Store.get(#{location})")
    call(:fetch, [location])
  end

  @doc """
  Lookup entities
  """
  @spec lookup([OCCI.Filter.t]) :: [OCCI.Node.t]
  def lookup(filter) do
    Logger.debug("Store.lookup(#{inspect filter})")
    call(:lookup, [filter])
  end

  @doc """
  Save entity
  """
  @spec create(OCCI.Entity.t, OCCI.Node.owner) :: OCCI.Node.t
  def create(entity, location \\ nil, owner \\ nil) do
    Logger.debug("Store.create(#{inspect entity})")
    location = if location do
      case call(:fetch, [location]) do
        nil -> location
        _ -> raise OCCI.Error, 409
      end
    else
      UUID.uuid4()
    end
    call(:store, [OCCI.Node.node(location: location, owner: owner, data: entity, serial: 0)])
  end

  @doc """
  Update given entity
  """
  @spec update(OCCI.Node.t) :: OCCI.Node.t
  def update(node) do
    Logger.debug("Store.update(#{inspect node})")
    case call(:fetch, OCCI.Node.node(node, :location)) do
      nil -> raise OCCI.Error, 404
      orig -> call(:store, [OCCI.Node.node(orig, data: OCCI.Node.node(node, :data))])
    end
  end

  @doc """
  Delete entity
  """
  @spec delete(OCCI.Node.location) :: boolean
  def delete(location) do
    Logger.debug("Store.delete(#{location})")
    case call(:fetch, location) do
      nil -> raise OCCI.Error, 404
      _ -> call(:delete, [location])
    end
  end

  ###
  ### Private
  ###
  defp call(name, args) do
    Agent.get_and_update(__MODULE__, fn %{ backend: {mod, state0}}=s ->
      case apply(mod, name, args ++ [state0]) do
        {:reply, ret, state} ->
          {ret, %{ s | backend: {mod, state}}}
        {:stop, reason, state} ->
          try do
            mod.terminate(:shutdown, state)
          rescue _ -> :ok
          end
          raise OCCI.Error, {mod, state, reason}
      end
    end)
  end
end
