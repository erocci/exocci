defmodule OCCI.Model do
  @moduledoc """
  Use this module to define categories for your application.

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
    scheme = case Keyword.get(opts, :scheme) do
               nil -> raise "Using OCCI.Model requires :scheme arg"
               s -> Helpers.__valid_scheme__(s)
             end
    Module.put_attribute(__CALLER__.module, :scheme, scheme)

    user_mixins_mod = Module.concat(__CALLER__.module, UserMixins)
    Module.put_attribute(__CALLER__.module, :imports, OrdSet.new)
    Module.put_attribute(__CALLER__.module, :kinds, Map.new)
    Module.put_attribute(__CALLER__.module, :mixins, Map.new)
    Module.put_attribute(__CALLER__.module, :actions, [])

    quote do
      require OCCI.Model
      import OCCI.Model

      if unquote(import_core) do
	      imports = Module.get_attribute(__MODULE__, :imports)
	      Module.put_attribute(__MODULE__, :imports, OrdSet.add(imports, OCCI.Model.Core))
      end

      defmodule unquote(user_mixins_mod) do
        @doc false
        def mixins, do: []

        @doc false
        def __mixins__, do: Map.new()
      end


      @doc """
      Return true if `name` is a valid kind module
      """
      @spec kind?(atom) :: boolean
      def kind?(mod) when is_atom(mod) do
        function_exported?(mod, :__occi_type__, 0) and mod.__occi_type__() == :kind
      end

      @doc """
      Return true if `name` if a valid mixin module
      """
      @spec mixin?(atom) :: boolean
      def mixin?(mod) when is_atom(mod) do
        function_exported?(mod, :__occi_type__, 0) and mod.__occi_type__() == :mixin
      end

      @doc """
      Given a list of categories, returns all attributes specs
      """
      def specs(categories) do
        Enum.reduce(categories, OrdSet.new(), fn category, acc ->
          OrdSet.merge(acc, category.__specs__())
        end)
      end

      @doc """
      Given a list of categories, returns list of required attributes
      """
      def required(categories) do
        Enum.reduce(categories, OrdSet.new(), fn category, acc ->
          OrdSet.merge(acc, category.required())
        end)
      end

      @doc """
      Given a list of categories, returns all action specifications
      """
      def actions(categories) do
        Enum.reduce(categories, OrdSet.new(), fn category, acc ->
          OrdSet.merge(acc, category.__actions__())
        end)
      end

      @doc """
      Return list of available mixins
      """
      @spec mixins() :: [ atom ]
      def mixins do
        Enum.reduce(@imports, OrdSet.merge(Map.values(@mixins), unquote(user_mixins_mod).mixins()),
          &(OrdSet.merge(&1.mixins(), &2)))
      end

      @doc """
      Add user mixin (tag)

      * `module`: module name, related to model name
      * `category`: category name
      """
      @spec add_mixin(module :: atom, category :: charlist() | String.t | atom) :: atom
      def add_mixin(module, category) do
        module = Module.concat(Module.split(__MODULE__) ++ Module.split(module))
        {scheme, term} = Helpers.__parse_category__(category)
        args = [ {:model, __MODULE__}, {:scheme, scheme}, {:term, term}, {:tag, true} ]
        q = quote do
          defmodule unquote(module) do
            use OCCI.Mixin, unquote(args)
          end
        end
        _ = Code.compile_quoted(q)

        :ok = update_user_mixins(Map.put(unquote(user_mixins_mod).__mixins__(), :"#{category}", module))
        module
      end

      @doc """
      Delete user mixin (tag)
      """
      @spec del_mixin(module :: atom) :: :ok | :error
      def del_mixin(module) do
        if function_exported?(module, :__occi_type__, 0) and module.__occi_type__() == :mixin and module.tag?() do
          category = module.category()
          true = :code.delete(module)
          :ok = update_user_mixins(unquote(user_mixins_mod).__mixins__() |> Map.delete(category))
        else
          :error
        end
      end

      @doc """
      Return module associated with the given category
      """
      @spec module(charlist() | String.t | atom) :: atom
      def module(name) do
	      name = :"#{name}"
	      Map.get_lazy(@kinds, name, fn ->
	        Map.get_lazy(@mixins, name, fn ->
	          Map.get_lazy(unquote(user_mixins_mod).mixins(), name, fn ->
	            Enum.find_value(@imports, &(&1.module(name)))
	          end)
	        end)
	      end)
      end

      @doc """
      Returns list of mixins applicable to a given kind
      """
      def applicable_mixins(kind) do
        Enum.reduce(mixins(), [], fn mixin, acc ->
          if mixin.apply?(kind), do: [ mixin | acc ], else: acc
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
        model = OCCI.Model.Core.Entity.__model__(entity)
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

      defp update_user_mixins(mixins) do
        mixins = Macro.escape(mixins)
        mod = unquote(user_mixins_mod)
        q = quote do
          defmodule unquote(mod) do
            @mixins unquote(mixins)

            @doc """
            Return list of user mixins
            """
            def mixins, do: Map.values(@mixins)

            @doc false
            def __mixins__, do: @mixins
          end
        end
        _ = Code.compiler_options(ignore_module_conflict: true)
        _ = Code.compile_quoted(q)
        :ok
      end

      @before_compile OCCI.Model
    end
  end

  @doc false
  defmacro __before_compile__(env) do
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

  Args:
  * parent: category or module kind's parent
  * scheme: if different from model's scheme
  * term: if different from lower-case module name
  * title: kind's description
  """
  defmacro kind({:__aliases__, _, name}, args \\ [], do_block \\ nil) do
    model = __CALLER__.module
    term = case Keyword.get(args, :term) do
             nil ->
               t = String.downcase(Enum.join(name, ""))
               :"#{t}"
             t -> :"#{t}"
           end
    scheme = case Keyword.get(args, :scheme) do
               nil -> Module.get_attribute(model, :scheme)
               s -> Helpers.__valid_scheme__(s)
             end
    modname = Helpers.__merge_modules__(model, name)

    parent = case Keyword.get(args, :parent) do
	             {:__aliases__, _, _}=aliases -> Macro.expand(aliases, __CALLER__)
	             nil -> nil
	             p -> model.__mod__(p)
	           end
    args = [
      {:model, model},
      {:parent, parent},
      {:scheme, scheme},
      {:term, term}
      | args ]

    kinds = Module.get_attribute(model, :kinds)
    Module.put_attribute(model, :kinds,
      Map.put(kinds, :"#{scheme}##{term}", Macro.expand(modname, __CALLER__)))

    do_block = do_block || Keyword.get(args, :do)

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
  defmacro mixin({:__aliases__, _, name}, args \\ [], do_block \\ nil) do
    model = __CALLER__.module
    term = case Keyword.get(args, :term) do
             nil ->
               t = String.downcase(Enum.join(name, ""))
               :"#{t}"
             t -> :"#{t}"
           end
    scheme = case Keyword.get(args, :scheme) do
               nil -> Module.get_attribute(model, :scheme)
               s -> Helpers.__valid_scheme__(s)
             end
    modname = Helpers.__merge_modules__(model, name)

    args = [
      {:model, model},
      {:depends, Keyword.get(args, :depends, [])},
      {:applies, Keyword.get(args, :applies, [])},
      {:scheme, scheme},
      {:term, term}
      | args ]

    do_block = do_block || Keyword.get(args, :do)

    mixins = Module.get_attribute(model, :mixins)
    Module.put_attribute(model, :mixins,
      Map.put(mixins, :"#{scheme}##{term}", Macro.expand(modname, __CALLER__)))

    quote do
      defmodule unquote(modname) do
	      use OCCI.Mixin, unquote(args)

	      unquote(do_block)
      end
    end
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
