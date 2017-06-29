defmodule OCCI.Kind do
  defmacro __using__(opts) do
    parent = Keyword.get(opts, :parent)
    opts = [ {:type, :kind} | opts ]
    
    quote do
      use OCCI.Category, unquote(opts)
      
      @parent unquote(parent)

      def parent, do: @parent

      def parent!, do: parent!(@parent)

      @doc """
      Creates a new entity of the kind
      """
      def new(attributes, mixins \\ []) do
        entity = %{
          id: nil,
          kind: @category,
          mixins: mixins,
          attributes: %{},
	  __internal__: %{
	    model: @model
	  }
        }
	Enum.reduce(attributes, entity, fn {key, value}, acc ->
	  set(acc, key, value)
	end)
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
	Enum.reverse(depends) ++ [ kind | mod(entity, kind).parent!() ]
      end
      
      ###
      ### Priv
      ###
      defp mod(entity, name) do
	model = get_in(entity, [:__internal__, :model]) || @model
	model.mod(name)
      end
      
      defp __get__(entity, key, []), do: raise OCCI.Error, {400, "Undefined attribute: #{key}"}
      defp __get__(entity, key, [ cat | categories ]) do
	try do
	  mod(entity, cat).__get__(entity, key)
	rescue
	  e in FunctionClauseError ->
	    __get__(entity, key, categories)
	  e in UndefinedFunctionError ->
	    __get__(entity, key, categories)
	end
      end

      defp __set__(entity, key, value, []), do: raise OCCI.Error, {400, "Undefined attribute: #{key}"}
      defp __set__(entity, key, value, [ cat | categories ]) do
	try do
	  mod(entity, cat).__set__(entity, key, value)
	rescue
	  e in FunctionClauseError ->
	    __set__(entity, key, value, categories)
	  e in UndefinedFunctionError ->
	    __set__(entity, key, value, categories)
	end
      end

      defp parent!(nil), do: []
      defp parent!(parent), do: OCCI.OrdSet.merge(@model.mod(parent).parent!(), [ parent ])
    end
  end
end
