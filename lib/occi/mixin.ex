defmodule OCCI.Mixin do
  defmacro __using__(opts) do
    depends = Keyword.get(opts, :depends, [])
    applies = Keyword.get(opts, :applies, [])
    model = Keyword.get_lazy(opts, :model, fn -> raise "Missing argument: model" end)
    {scheme, term} = OCCI.Model.parse_category(__CALLER__.module)

    quote do
      @model unquote(model)

      @category __MODULE__
      @scheme unquote(scheme)
      @term unquote(term)
      
      @depends unquote(depends)
      @applies unquote(applies)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term

      def depends, do: @depends
      def applies, do: @applies
    end
  end
end
