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

      def depends! do
	Enum.reduce(@depends, [], fn dep, acc ->
	  if dep in acc do
	    acc
	  else
	    depends = case @model.mod(dep) do
			nil -> []
			mod -> mod.depends!()
		      end
	    acc ++ [ dep | depends ]
	  end
	end)
      end

      def apply?(kind) do
	kind = :"#{kind}"
	Enum.any?(@applies, fn
	  ^kind -> true
	  apply -> Enum.any?(@model.mod(apply).parent!(), fn ^kind -> true; _ -> false end)
	end)
      end
    end
  end
end
