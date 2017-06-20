defmodule OCCI.Model do
  
  @doc false
  defmacro __using__(opts) do
    import_core = Keyword.get(opts, :core, true)
    user_mixins_mod = Module.concat(__CALLER__.module, UserMixins)
    Module.put_attribute(__CALLER__.module, :imports, MapSet.new)
    Module.put_attribute(__CALLER__.module, :kinds, Map.new)
    Module.put_attribute(__CALLER__.module, :mixins, Map.new)

    quote do
      require OCCI.Model
      import OCCI.Model
      
      if unquote(import_core) do
	imports = Module.get_attribute(__MODULE__, :imports)
	Module.put_attribute(__MODULE__, :imports, MapSet.put(imports, OCCI.Model.Core))
      end
      
      def_user_mixins(unquote(user_mixins_mod), Map.new)

      def kind?(name) do
	name = :"#{name}"
	Map.has_key?(@kinds, name) or Enum.any?(@imports, &(&1.kind?(name)))
      end

      def kinds do
	Enum.reduce(@imports, @kinds,
	  &(Map.merge(&1.kinds(), &2)))
      end

      def mixin?(name) do
	name = :"#{name}"
	Map.has_key?(@mixins, name)
	or Map.has_key?(unquote(user_mixins_mod).mixins(), name)
	or Enum.any?(@imports, &(&1.mixin?(name)))
      end

      def mixins do
	Enum.reduce(@imports, Map.merge(@mixins, unquote(user_mixins_mod).mixins()),
	  &(Map.merge(&1.mixins(), &2)))
      end

      def mixin(name) do
	mixins = Map.put(unquote(user_mixins_mod).mixins(), :"#{name}", nil)
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end

      def del_mixin(name) do
        mixins = unquote(user_mixins_mod).mixins() |> Map.delete(:"#{name}")
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end

      def mod(name) do
	name = :"#{name}"
	Map.get_lazy(@kinds, name, fn ->
	  Map.get_lazy(@mixins, name, fn ->
	    Map.get_lazy(unquote(user_mixins_mod).mixins(), name, fn ->
	      Enum.find_value(@imports, &(&1.mod(name)))
	    end)
	  end)
	end)
      end
    end
  end

  defmacro import_model(name) do
    mod = Macro.expand(name, __CALLER__)
    imports = Module.get_attribute(__CALLER__.module, :imports)
    Module.put_attribute(__CALLER__.module, :imports, MapSet.put(imports, mod))
  end

  defmacro kind(name, args \\ []) do
    model = __CALLER__.module

    modname = mod_name(name, args, __CALLER__)
    name = name |> to_atom
    parent = case Keyword.get(args, :parent) do
	       {:__aliases__, _, _}=aliases ->
		 Macro.expand(aliases, __CALLER__).category()
	       nil -> nil
	       p -> :"#{p}"
	     end
    attributes = Keyword.get(args, :attributes, [])
    do_block = Keyword.get(args, :do)

    kinds = Module.get_attribute(model, :kinds)
    Module.put_attribute(model, :kinds, Map.put(kinds, name, modname))

    quote do
      defmodule unquote(modname) do
        use OCCI.Kind,
	  category: unquote(name),
          parent: unquote(parent),
          model: unquote(model),
          attributes: unquote(attributes)

	unquote(do_block)
      end
    end
  end

  defmacro mixin(name, args \\ []) do
    model = __CALLER__.module

    modname = mod_name(name, args, __CALLER__)
    name = name |> to_atom
    depends = Keyword.get(args, :depends, [])
    applies = Keyword.get(args, :applies, [])
    attributes = Keyword.get(args, :attributes, [])
    do_block = Keyword.get(args, :do)
    
    mixins = Module.get_attribute(model, :mixins)
    Module.put_attribute(model, :mixins, Map.put(mixins, name, modname))

    quote do
      defmodule unquote(modname) do
	use OCCI.Mixin,
	  category: unquote(name),
	  model: unquote(model),
	  depends: unquote(depends),
	  applies: unquote(applies),
	  attributes: unquote(attributes)

	unquote(do_block)
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

  def to_atom(nil), do: nil
  def to_atom(s), do: :"#{s}"

  def mod_encode(name) do
    URI.encode(name, &URI.char_unreserved?/1)
  end

  def mod_name(name, args, env) do
    case Keyword.get(args, :alias) do
      nil ->
	mod_encode("#{name}") |> to_atom
      {:__aliases__, _, _}=aliases ->
	Module.concat([env.module, Macro.expand(aliases, env)])
    end
  end
end
