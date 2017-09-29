defmodule OCCI.Kind do
  defmacro __using__(opts) do
    parent = Keyword.get(opts, :parent)
    opts = [ {:type, :kind} | opts ]

    Module.put_attribute(__CALLER__.module, :actions, [])
    Module.put_attribute(__CALLER__.module, :action_mods, [])

    quote do
      use OCCI.Category, unquote(opts)
      alias OCCI.OrdSet

      @before_compile OCCI.Kind

      @parent unquote(parent)

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

      def get(entity, key) when is_atom(key) do
	      __get__(entity, key, categories(entity))
      end
      def get(entity, key) do
	      __get__(entity, :"#{key}", categories(entity))
      end

      def set(entity, key, value) when is_atom(key) do
	      __set__(entity, key, value, categories(entity))
      end
      def set(entity, key, value) do
	      __set__(entity, :"#{key}", value, categories(entity))
      end

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
          ids ->
            raise OCCI.Error, {422, "Missing attributes: " <> Enum.join(ids, " ")}
        end
      end

      defp missing_attributes(entity) do
        Enum.reduce(categories(entity), [], fn cat, acc0 ->
          case cat do
            nil -> acc0
            mod ->
              Enum.reduce(mod.__required__(), acc0, fn id, acc1 ->
                case OCCI.Model.Core.Entity.get(entity, id) do
                  nil -> [ id | acc1 ]
                  _ -> acc1
                end
              end)
          end
        end)
      end

      defp __get__(entity, key, []), do: raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      defp __get__(entity, key, [ cat | categories ]) do
	      try do
	        cat.__get__(entity, key)
	      rescue
          KeyError -> __get__(entity, key, categories)
	      end
      end

      defp __set__(entity, key, value, []), do: raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      defp __set__(entity, key, value, [ cat | categories ]) do
	      try do
	        cat.__set__(entity, key, value)
	      rescue
          KeyError -> __set__(entity, key, value, categories)
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
