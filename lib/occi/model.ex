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
  alias OCCI.OrdSet
  alias OCCI.Category.Helpers

  @doc false
  defmacro __using__(opts) do
    import_core = Keyword.get(opts, :core, true)
    user_mixins_mod = Module.concat(__CALLER__.module, UserMixins)
    Module.put_attribute(__CALLER__.module, :imports, OrdSet.new)
    Module.put_attribute(__CALLER__.module, :kinds, Map.new)
    Module.put_attribute(__CALLER__.module, :mixins, Map.new)
    Module.put_attribute(__CALLER__.module, :actions, [])

    quote do
      require OCCI.Model
      import OCCI.Model

      import OCCI.Category, only: [action: 2]

      if unquote(import_core) do
	      imports = Module.get_attribute(__MODULE__, :imports)
	      Module.put_attribute(__MODULE__, :imports, OrdSet.add(imports, OCCI.Model.Core))
      end

      def_user_mixins(unquote(user_mixins_mod), Map.new)

      def new(data) when is_map(data) do
        kind = Map.get_lazy(data, :kind, fn -> raise OCCI.Error, {422, "Missing attribute: kind"} end)
        mixins = Map.get(data, :mixins, [])
        case mod(kind) do
          nil -> raise OCCI.Error, {422, "Invalid category: #{kind}"}
          mod -> mod(kind).new(data, mixins, __MODULE__)
        end
      end

      def new(kind, attributes, mixins \\ []) do
        case mod(kind) do
          nil -> raise OCCI.Error, {422, "Invalid category: #{kind}"}
	        mod -> mod(kind).new(attributes, mixins, __MODULE__)
        end
      end

      @doc """
      Return true if `name` is a valid kind id
      """
      @spec kind?(charlist() | String.t | atom) :: boolean
      def kind?(name) do
	      name = :"#{name}"
	      Map.has_key?(@kinds, name) or Enum.any?(@imports, &(&1.kind?(name)))
      end

      @doc """
      Return available kinds in this model and imported ones as a map id -> module
      """
      @spec kinds() :: map
      def kinds do
	      Enum.reduce(@imports, @kinds,
	        &(Map.merge(&1.kinds(), &2)))
      end

      @doc """
      Return true if `name` if a valid mixin id
      """
      @spec mixin?(charlist() | String.t | atom) :: boolean
      def mixin?(name) do
	      name = :"#{name}"
	      Map.has_key?(@mixins, name)
	      or Map.has_key?(unquote(user_mixins_mod).mixins(), name)
	      or Enum.any?(@imports, &(&1.mixin?(name)))
      end

      @doc """
      Return defined mixins in this model and imported ones
      """
      @spec mixins() :: map
      def mixins do
	      Enum.reduce(@imports, Map.merge(@mixins, unquote(user_mixins_mod).mixins()),
	        &(Map.merge(&1.mixins(), &2)))
      end

      @doc """
      Add user mixin (tag)
      """
      @spec add_mixin(charlist() | String.t | atom) :: :ok
      def add_mixin(name) do
	      mixins = Map.put(unquote(user_mixins_mod).mixins(), :"#{name}", nil)
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end

      @doc """
      Delete user mixin (tag)
      """
      @spec del_mixin(charlist() | String.t | atom) :: :ok
      def del_mixin(name) do
        mixins = unquote(user_mixins_mod).mixins() |> Map.delete(:"#{name}")
        OCCI.Model.def_user_mixins(unquote(user_mixins_mod), mixins)
      end

      @doc """
      Return title of given category
      """
      @spec title(String.t | charlist() | atom) :: String.t
      def title(category), do: mod(category).title

      @doc """
      Return module name for a given category id

      TODO: might it be hidden for user ?
      """
      @spec mod(charlist() | String.t | atom) :: atom
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

      @doc """
      Given a list of categories, returns all attributes specs
      """
      def specs(categories) do
        Enum.reduce(categories, OrdSet.new(), fn category, acc ->
          OrdSet.merge(acc, mod(category).__specs__())
        end)
      end

      @doc """
      Returns list of mixins applicable to a given kind
      """
      def applicable_mixins(kind) do
        Enum.reduce(mixins(), [], fn {id, _}, acc ->
          if mod(id).apply?(kind), do: [ id | acc ], else: acc
        end)
      end

      @doc false
      def __imports__ do
        Enum.reduce(@imports, OCCI.OrdSet.new(),
          &(OCCI.OrdSet.merge(&2, [ &1 | &1.__imports__() ])))
      end

      @doc false
      #
      # When launching an action on an entity, look for implementation in
      # creation model, creation model's imports, then related category.
      #
      def __exec__(action, entity) do
        fun = :"__#{OCCI.Action.id(action)}__"
        attrs = OCCI.Action.attributes(action)
        related = OCCI.Action.related(action)
        related_mod = OCCI.Action.__related_mod__(action)
        model = OCCI.Model.Core.Entity.__created_in__(entity)
        __exec__(entity, attrs, related, related_mod, fun, [ model | model.__imports__() ])
      end

      defp __exec__(entity, attrs, _related, related_mod, fun, []) do
        try do
          apply(related_mod, fun, [entity, attrs])
        rescue UndefinedFunctionError ->
            # No implementation found, returns entity
            entity
        end
      end
      defp __exec__(entity, attrs, related, related_mod, fun, [ model | models ]) do
        try do
          apply(model, fun, [entity, attrs])
        rescue e in UndefinedFunctionError ->
            __exec__(entity, attrs, related, related_mod, fun, models)
        end
      end

      @before_compile OCCI.Model
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    # Generate action implementations
    Helpers.__def_actions__(env)

    # Generate documentation
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
    Module.put_attribute(__CALLER__.module, :imports, OrdSet.add(imports, mod))
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
