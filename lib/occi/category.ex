defmodule OCCI.Category do

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name,
      fn -> raise "Missing argument: name" end)
    model = Keyword.get_lazy(opts, :model,
      fn -> raise "Missing argument: model" end)
    title = Keyword.get_lazy(opts, :title, fn ->
      case Keyword.get(opts, :type) do
	:kind -> "Kind #{name}"
	:mixin -> "Mixin #{name}"
	_ -> "Category #{name}"
      end
    end)
      
    {scheme, term} = parse_category(name)

    quote do
      require OCCI.Category
      import OCCI.Category

      @model unquote(model)
      
      @category unquote(name)
      @scheme unquote(scheme)
      @term unquote(term)
      @title unquote(title)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term
      def title, do: @title
    end
  end

  ###
  ### Priv
  ###
  defp parse_category(name) do
    case String.split("#{name}", "#") do
      [scheme, term] -> {:"#{scheme}#", :"#{term}"}
      _ -> raise "Invalid category: #{name}"
    end
  end
end
