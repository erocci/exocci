defmodule OCCI.Kind do
  defmacro __using__(opts) do
    parent = Keyword.get(opts, :parent)
    opts = [ {:type, :kind} | opts ]

    quote do
      use OCCI.Category, unquote(opts)
      alias OCCI.OrdSet

      Module.register_attribute(__MODULE__, :actions, accumulate: true)
      Module.register_attribute(__MODULE__, :action_mods, accumulate: true)

      @before_compile OCCI.Kind
      @parent unquote(parent)
      @struct %{
        __struct__: OCCI.Model.Core.Entity,
        id: nil,
        kind: __MODULE__,
        mixins: [],
        attributes: %{},
        __node__: %OCCI.Node{}
      }

      @behaviour Access

      @doc false
      def __struct__(), do: @struct

      def parent, do: @parent

      def parent!, do: parent!(@parent)

      @doc """
      Creates a new entity of the kind
      """
      def new(attributes, mixins \\ [], model \\ OCCI.Model.Core) do
        entity = %{
          id: nil,
          kind: __MODULE__,
          mixins: mixins,
          attributes: %{},
          __struct__: OCCI.Model.Core.Entity,
	        __node__: %OCCI.Node{
            model: model
          }
        }
	      entity = Enum.reduce(attributes, entity, fn
          {:kind, _}, acc -> acc
          {:mixins, _}, acc -> acc
          {key, value}, acc -> set(acc, key, value)
	      end)
        complete(entity)
      end

      @doc """
      Get the attribute from entity, returning default value if not present
      """
      def get(entity, key, default \\ nil) do
        case fetch(entity, key) do
          :error -> default
          {:ok, nil} -> default
          {:ok, value} -> value
        end
      end

      @doc """
      (Implements Access callback)

      Returns:
      * :error -> key does not exists or value is not set and no default value
      * {:ok, nil} -> key exists but value is not set (and no default value)
      * {:ok, value} -> key exists and value is set (or there is a default value)
      """
      def fetch(entity, key) when is_atom(key) do
	      __fetch__(entity, key, categories(entity))
      end
      def fetch(entity, key) do
	      __fetch__(entity, :"#{key}", categories(entity))
      end

      def set(entity, key, value) when is_atom(key) do
	      __set__(entity, key, value, categories(entity))
      end
      def set(entity, key, value) do
	      __set__(entity, :"#{key}", value, categories(entity))
      end

      def get_and_update(entity, key, fun) do
        cur_val = get(entity, key, nil)
        case fun.(cur_val) do
          {cur_val, new_val} ->
            {cur_val, set(entity, key, new_val)}
          :pop ->
            {cur_val, delete(entity, key)}
        end
      end

      def pop(entity, key) do
        cur_val = get(entity, key)
        {cur_val, delete(entity, key)}
      end

      def delete(entity, key) when key in [:id, :kind, :mixins, :attributes, :model, :node], do: entity
      def delete(entity, :owner) do
        Map.put(entity, :__node__, Map.put(entity.__node__, :owner, nil))
      end
      def delete(entity, :serial) do
        Map.put(entity, :__node__, Map.put(entity.__node__, :serial, nil))
      end
      def delete(entity, key) when is_atom(key) do
        if key in required(entity) do
          entity
        else
          Map.put(entity, :attributes, Map.delete(entity.attributes, key))
        end
      end
      def delete(entity, key), do: delete(entity, :"#{key}")

      @doc """
      Return all categories attribute definition must be searched for.

      [
      mixin0
	    mixin0 deps
	    mixin1
	    mixin1 deps
	    ...
	    kind
	    kind parents
      ]
      """
      def categories(entity) do
	      depends = Enum.reduce(Map.get(entity, :mixins, []), OrdSet.new(), fn mixin, acc ->
          OrdSet.merge(acc, [ mixin | mixin.depends!() ])
	      end)
	      kind = Map.get(entity, :kind)
	      parents = kind.parent!()
	      Enum.reverse(depends) ++ [ kind | parents ]
      end

      @doc """
      Return required attribute keys
      """
      def required(entity) do
        Enum.reduce(categories(entity), OrdSet.new(), &(OrdSet.merge(&2, &1.__required__())))
      end

      ###
      ### Priv
      ###
      # raise OCCI.Error if missing attributes, else return entity
      defp complete(entity) do
        case missing_attributes(entity) do
          [] -> entity
          ids -> raise OCCI.Error, {422, "Missing attributes: " <> Enum.join(ids, " ")}
        end
      end

      defp missing_attributes(entity) do
        Enum.reduce(required(entity), [], fn key, acc ->
          case OCCI.Model.Core.Entity.fetch(entity, key) do
            {:ok, nil} -> [ key | acc ]
            {:ok, _} -> acc
          end
        end)
      end

      defp __fetch__(entity, key, []), do: :error
      defp __fetch__(entity, key, [ cat | categories ]) do
	      try do
	        cat.__fetch_this__(entity, key)
	      rescue
          FunctionClauseError -> __fetch__(entity, key, categories)
	      end
      end

      defp __set__(entity, key, value, []), do: raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      defp __set__(entity, key, value, [ cat | categories ]) do
	      try do
	        cat.__set__(entity, key, value)
	      rescue
          FunctionClauseError -> __set__(entity, key, value, categories)
	      end
      end

      defp parent!(nil), do: []
      defp parent!(parent) do
	      OrdSet.add(parent.parent!(), parent)
      end
    end
  end

  defmacro __before_compile__(_opts) do
    OCCI.Category.Helpers.__gen_doc__(__CALLER__)
    OCCI.Category.Helpers.__def_attributes__(__CALLER__)
    OCCI.Category.Helpers.__def_actions__(__CALLER__)
  end
end
