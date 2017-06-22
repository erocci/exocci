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
          attributes: %{}
        }
	#Enum.reduce(attributes, entity, fn {key, value} ->
	#  set(entity, key, value)
	#end)
	entity
      end

      ###
      ### Priv
      ###
      defp parent!(nil), do: []
      defp parent!(parent) do
	ancestors = @model.mod(parent).parent!()
	# avoid loops
	if parent in ancestors, do: ancestors, else: [ parent | ancestors ]
      end
    end
  end
end
