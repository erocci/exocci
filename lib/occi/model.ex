defmodule OCCI.Model do
  @moduledoc """
  Use this module to define categories for your application.

  Defines the following functions for creating entities:
  * `new/1`: creates entity from map, similar to JSON rendering
  * `new/3`: creates entity from kind, mixins and attributes

  Defines the following functions for manipulating categories:
  * `kind?/1`: check a kind is part of this model
  * `kinds/0`: returns list of supported kinds, including imported ones
  * `mixin?/1`: check a mixin is part of this model
  * `mixins/0`: returns list of availables mixins
  * `mixin/1`: add a user mixin
  * `del_mixin/1`: delete a user mixin

  Available macros:
  * `extends/1`: import categories from another model
  * `kind/3`: defines a new kind
  * `mixin/2`: defines a new mixin
  """
  alias OCCI.Category.Helpers

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
        case mod(kind) do
          nil -> raise OCCI.Error, {422, "Invalid category: #{kind}"}
          mod -> mod(kind).new(data, mixins)
        end
      end

      def new(kind, attributes, mixins \\ []) do
        case mod(kind) do
          nil -> raise OCCI.Error, {422, "Invalid category: #{kind}"}
	        mod -> mod(kind).new(attributes, mixins)
        end
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

      @before_compile OCCI.Model
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    {line, doc} = case Module.get_attribute(env.module, :moduledoc) do
                    nil -> {2, ""}
                    {line, doc} -> {line, doc}
                  end

    doc = doc |>
      gen_exts_doc(Module.get_attribute(env.module, :imports)) |>
      gen_kinds_doc(Module.get_attribute(env.module, :kinds)) |>
      gen_mixins_doc(Module.get_attribute(env.module, :mixins))
    Module.put_attribute(env.module, :moduledoc, {line, doc})
  end

  @doc """
  Import categories from a model.
  A model is represented by an elixir module.

  OCCI.Model.Core is imported by default in all models.
  """
  defmacro extends(name) do
    mod = Macro.expand(name, __CALLER__)
    imports = Module.get_attribute(__CALLER__.module, :imports)
    Module.put_attribute(__CALLER__.module, :imports, MapSet.put(imports, mod))
  end

  @doc """
  Defines a new kind
  """
  defmacro kind(name, args \\ [], do_block \\ nil) do
    modname = Helpers.__mod_name__(name, args, __CALLER__)
    name = name |> Helpers.__to_atom__
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

  @doc """
  Defines a new mixin
  """
  defmacro mixin(name, args \\ []) do
    model = __CALLER__.module
    name = name |> Helpers.__to_atom__
    modname = Helpers.__mod_name__(name, args, __CALLER__)
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

  ###
  ### Priv
  ###
  defp gen_exts_doc(doc, exts) do
    if Enum.empty?(exts) do
      doc
    else
      doc = doc <> """

      Imported extensions:
      """
      Enum.reduce(exts, doc, fn ext, acc ->
        acc <> """
        * `#{ext}`
        """
      end)
    end
  end

  defp gen_kinds_doc(doc, kinds) do
    if Enum.empty?(kinds) do
      doc
    else
      doc = doc <> """

      Defined Kinds:
      """
      Enum.reduce(kinds, doc, fn {kind, _}, acc ->
        acc <> """
        * _#{kind}_
        """
      end)
    end
  end

  defp gen_mixins_doc(doc, mixins) do
    if Enum.empty?(mixins) do
      doc
    else
      doc = doc <> """

      Defined Mixins:
      """
      Enum.reduce(mixins, doc, fn {mixin, _}, acc ->
        acc <> """
        * _#{mixin}_
        """
      end)
    end
  end
end
