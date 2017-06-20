defmodule OCCI.Mixin do
  defmacro __using__(opts) do
    model = Keyword.get_lazy(opts, :model, fn -> raise "Missing argument: model" end)

    category = Keyword.get_lazy(opts, :category, fn -> raise "Missing argument: category" end)
    {scheme, term} = OCCI.Model.parse_category(category)

    depends = Keyword.get(opts, :depends, []) |> Enum.map(&(:"#{&1}"))
    applies = Keyword.get(opts, :applies, []) |> Enum.map(&(:"#{&1}"))

    quote do
      @model :"#{unquote(model)}"

      @category unquote(category)
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
