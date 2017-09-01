defmodule OCCI.Kind do
  defmacro __using__(opts) do
    parent = Keyword.get(opts, :parent)
    opts = [ {:type, :kind} | opts ]

    Module.put_attribute(__CALLER__.module, :actions, [])

    quote do
      use OCCI.Category, unquote(opts)
      @before_compile OCCI.Kind

      @parent unquote(parent)

      def parent, do: @parent

      def parent!, do: parent!(@parent)

      @doc """
      Creates a new entity of the kind
      """
      def new(attributes, mixins \\ [], model \\ nil) do
        entity = %{
          id: nil,
          kind: @category,
          mixins: Enum.map(mixins, &(:"#{&1}")),
          attributes: %{},
	        __node__: %OCCI.Node{
            defined_in: @model,
            created_in: model || @model
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
	      __set__(entity, "#{key}", value, categories(entity))
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
	      depends = Enum.reduce(Map.get(entity, :mixins, []), OCCI.OrdSet.new(), fn mixin, acc ->
	        case mod(entity, mixin) do
	          nil -> OCCI.OrdSet.add(acc, mixin)
	          mod -> OCCI.OrdSet.merge(acc, [ mixin | mod.depends!() ])
	        end
	      end)
	      kind = Map.get(entity, :kind)
	      parents = case mod(entity, kind) do
		                nil -> []
		                mod -> mod.parent!()
		              end
	      Enum.reverse(depends) ++ [ kind | parents ]
      end

      ###
      ### Priv
      ###
      defp mod(entity, name) do
	      model = OCCI.Model.Core.Entity.__defined_in__(entity) || @model
	      model.mod(name)
      end

      # raise OCCI.Error if missing attributes, else return entity
      defp complete(entity) do
	      case missing_attributes(entity) do
	        [] -> entity
	        ids ->
	          names = Enum.join(ids, " ")
	          raise OCCI.Error, {422, "Missing attributes: #{names}"}
	      end
      end

      defp missing_attributes(entity) do
	      Enum.reduce(categories(entity), [], fn cat, acc0 ->
	        case mod(entity, cat) do
	          nil -> acc0
	          mod ->
	            Enum.reduce(mod.required(), acc0, fn id, acc1 ->
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
	        mod(entity, cat).__get__(entity, key)
	      rescue
	        FunctionClauseError ->
	          __get__(entity, key, categories)
	        UndefinedFunctionError ->
	          __get__(entity, key, categories)
	      end
      end

      defp __set__(entity, key, value, []), do: raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      defp __set__(entity, key, value, [ cat | categories ]) do
	      try do
	        mod = mod(entity, cat)
	        mod.__set__(entity, key, value)
	      rescue
	        FunctionClauseError ->
	          __set__(entity, key, value, categories)
	        UndefinedFunctionError ->
	          __set__(entity, key, value, categories)
	      end
      end

      defp parent!(nil), do: []
      defp parent!(parent) do
	      OCCI.OrdSet.add(@model.mod(parent).parent!(), parent)
      end
    end
  end

  defmacro __before_compile__(_opts) do
    OCCI.Category.Helpers.__gen_doc__(__CALLER__)
    OCCI.Category.Helpers.__def_attributes__(__CALLER__)
    OCCI.Category.Helpers.__def_actions__(__CALLER__)
  end
end
