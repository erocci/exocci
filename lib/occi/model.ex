defmodule OCCI.Model do
  require OCCI.Model.Core
  
  @doc false
  defmacro __using__(_) do
    user_mixins_mod = Module.concat(__CALLER__.module, UserMixins)
    Module.put_attribute(__CALLER__.module, :kinds, MapSet.new)
    Module.put_attribute(__CALLER__.module, :mixins, MapSet.new)
    
    quote do
      require OCCI.Model
      import OCCI.Model

      def_user_mixins(unquote(user_mixins_mod), MapSet.new)

      def kinds, do: @kinds

      def mixins do
	MapSet.union(@mixins, unquote(user_mixins_mod).mixins())
      end

      def mixin(name) do
	mixins = MapSet.put(unquote(user_mixins_mod).mixins(), :"#{name}")
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end

      def del_mixin(name) do
        mixins = unquote(user_mixins_mod).mixins() |> MapSet.delete(:"#{name}")
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end
    end
  end

  defmacro kind(name, args \\ []) do
    name = :"#{name}"
    parent = case Keyword.get(args, :parent, nil) do
	       nil -> OCCI.Model.Core.kind_resource
	       p -> p
	     end
    attributes = Keyword.get(args, :attributes, [])

    model = __CALLER__.module
    kinds = Module.get_attribute(model, :kinds) || MapSet.new
    Module.put_attribute(model, :kinds, MapSet.put(kinds, name))

    quote do
      defmodule unquote(name) do
        use OCCI.Kind,
          parent: :"#{unquote(parent)}",
          model: unquote(model),
          attributes: unquote(attributes)
      end
    end
  end

  defmacro mixin(name, args \\ []) do
    name = :"#{name}"
    depends = Keyword.get(args, :depends, [])
    applies = Keyword.get(args, :applies, [])
    attributes = Keyword.get(args, :attributes, [])
    
    model = __CALLER__.module
    mixins = Module.get_attribute(model, :mixins) || MapSet.new
    Module.put_attribute(model, :mixins, MapSet.put(mixins, name))

    quote do
      defmodule unquote(name) do
	use OCCI.Mixin,
	  model: unquote(model),
	  depends: unquote(depends),
	  applies: unquote(applies),
	  attributes: unquote(attributes)
      end
    end
  end

  def def_user_mixins(mod, user_mixins) do
    user_mixins = Macro.escape(user_mixins)
    quoted = quote do
      defmodule unquote(mod) do
        def mixins, do: unquote(user_mixins)
      end
    end
    _ = Code.compiler_options(ignore_module_conflict: true)
    _ = Code.compile_quoted(quoted)
    :ok
  end

  def parse_category(name) do
    case String.split("#{name}", "#") do
      [scheme, term] -> {:"#{scheme}#", :"#{term}"}
      _ -> raise "Invalid category: #{name}"
    end
  end
end
