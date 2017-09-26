defmodule OCCI.Mixin do
  alias OCCI.Category.Helpers

  defmacro __using__(opts) do
    depends = Keyword.get(opts, :depends, []) |> Enum.map(&(:"#{&1}"))
    applies = Keyword.get(opts, :applies, []) |> Enum.map(&(:"#{&1}"))

    opts = [ {:type, :mixin} | opts ]

    Module.put_attribute(__CALLER__.module, :actions, [])
    Module.put_attribute(__CALLER__.module, :action_mods, [])

    quote do
      use OCCI.Category, unquote(opts)
      @before_compile OCCI.Mixin

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

  defmacro __before_compile__(_opts) do
    Helpers.__gen_doc__(__CALLER__)
    Helpers.__def_attributes__(__CALLER__)
    Helpers.__def_actions__(__CALLER__)
  end
end
