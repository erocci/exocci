defmodule OCCI.Category do

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name,
      fn -> raise "Missing argument: name" end)
    model = Keyword.get_lazy(opts, :model,
      fn -> raise "Missing argument: model" end)
    {scheme, term} = parse_category(name)

    quote do
      require OCCI.Category
      import OCCI.Category

      @model :"#{unquote(model)}"
      
      @category unquote(name)
      @scheme unquote(scheme)
      @term unquote(term)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term
    end
  end

  #def def_category(env) do
  #  quote do
  #    defmacro category
  #  end
  #end

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
