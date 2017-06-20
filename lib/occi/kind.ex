defmodule OCCI.Kind do
  defmacro __using__(opts) do
    parent = Keyword.get_lazy(opts, :parent, fn -> raise "Missing argument: parent" end)
    model = Keyword.get_lazy(opts, :model, fn -> raise "Missing argument: model" end)
    {scheme, term} = OCCI.Model.parse_category(__CALLER__.module)

    quote do
      @model unquote(model)

      @category __MODULE__
      @scheme unquote(scheme)
      @term unquote(term)
      
      @parent unquote(parent)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term

      def parent, do: @parent
    end
  end
end
