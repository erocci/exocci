defmodule OCCI.Mixin do
  defmacro __using__(opts) do
    depends = Keyword.get(opts, :depends, []) |> Enum.map(&(:"#{&1}"))
    applies = Keyword.get(opts, :applies, []) |> Enum.map(&(:"#{&1}"))

    opts = [ {:type, :mixin} | opts ]

    quote do
      use OCCI.Category, unquote(opts)
      
      @depends unquote(depends)
      @applies unquote(applies)

      def depends, do: @depends
      def applies, do: @applies

      def depends! do
	Enum.reduce(@depends, OCCI.OrdSet.new(), fn dep, acc ->
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
