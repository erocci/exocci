defmodule OCCI.Backend do
  @moduledoc """
  Defines backend behaviour

  When `use OCCI.Backend`, provides default implementations for init/1
  and terminate/2
  """
  alias OCCI

  defstruct id: nil, mountpoint: nil, mod: nil, args: nil

  @type t :: %OCCI.Backend{}

  @callback init(model :: atom, args :: any) ::
  {:ok, state} |
  {:stop, reason :: any} when state: any

  @callback fetch(OCCI.Node.location, state) ::
  {:reply, OCCI.Node.t | nil, new_state} |
  {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback lookup(OCCI.Filter.t, state) ::
  {:reply, [OCCI.Node.t], new_state} |
  {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback store(OCCI.Node.t, state) ::
  {:reply, OCCI.Node.t, new_state} |
  {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback delete(OCCI.Node.location, state) ::
  {:reply, :ok | :error, new_state} |
  {:stop, reason :: term, new_state} when state: term, new_state: term

  @callback terminate(reason :: :atom, state) :: :ok when state: term

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour OCCI.Backend

      @doc false
      def init(args) do
        {:ok, args}
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      defoverridable [init: 1, terminate: 2]
    end
  end
end
