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

      def new(data) when is_map(data) do
        kind = Map.get_lazy(data, :kind, fn -> raise OCCI.Error, {422, "Missing attribute: kind"} end)
        mixins = Map.get(data, :mixins, [])
        mod(kind).new(data, mixins)
      end

      def new(kind, attributes, mixins \\ []) do
	      mod(kind).new(attributes, mixins)
      end

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

  defmacro kind(name, args \\ [], do_block \\ nil) do
    modname = OCCI.Category.Helpers.mod_name(name, args, __CALLER__)
    name = name |> OCCI.Category.Helpers.to_atom
    model = __CALLER__.module
    parent = case Keyword.get(args, :parent) do
	             {:__aliases__, _, _}=aliases ->
		             Macro.expand(aliases, __CALLER__).category()
	             nil -> nil
	             p -> :"#{p}"
	           end
    args = [
      {:name, name},
      {:model, model},
      {:parent, parent}
      | args ]

    kinds = Module.get_attribute(model, :kinds)
    Module.put_attribute(model, :kinds, Map.put(kinds, name, modname))

    quote do
      defmodule unquote(modname) do
        use OCCI.Kind, unquote(args)

	      unquote(do_block)
      end
    end
  end

  defmacro mixin(name, args \\ []) do
    model = __CALLER__.module
    name = name |> OCCI.Category.Helpers.to_atom
    modname = OCCI.Category.Helpers.mod_name(name, args, __CALLER__)
    args = [
      {:name, name}, {:model, model},
      {:depends, Keyword.get(args, :depends, [])},
      {:applies, Keyword.get(args, :applies, [])}
      | args ]

    do_block = Keyword.get(args, :do)

    mixins = Module.get_attribute(model, :mixins)
    Module.put_attribute(model, :mixins, Map.put(mixins, name, modname))

    quote do
      defmodule unquote(modname) do
	      use OCCI.Mixin, unquote(args)

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
end
