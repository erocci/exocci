defmodule OCCI.Kind do
  defmacro __using__(opts) do
    model = Keyword.get_lazy(opts, :model, fn -> raise "Missing argument: model" end)

    category = Keyword.get_lazy(opts, :category, fn -> raise "Missing argument: category" end)
    {scheme, term} = OCCI.Model.parse_category(category)

    parent = Keyword.get(opts, :parent)

    quote do
      @model :"#{unquote(model)}"

      @category unquote(category)
      @scheme unquote(scheme)
      @term unquote(term)
      
      @parent unquote(parent)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term

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
