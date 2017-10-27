defmodule OCCI.Category.Helpers do
  @moduledoc """
  Collection of functions for compiling OCCI category modules.
  """

  @doc false
  def __gen_doc__(_env) do
  end

  @doc false
  def __def_attributes__(env) do
    specs = Module.get_attribute(env.module, :attributes, [])

    requires = Enum.reduce(specs, MapSet.new, fn spec, acc ->
      case Keyword.get(spec, :check) do
	      nil -> acc
	      {typemod, _} -> MapSet.put(acc, typemod)
      end
    end)
    ast = for mod <- requires do
      quote do
	      require unquote(mod)
      end
    end
    Module.eval_quoted(env.module, ast)

    defaults = Enum.reduce(specs, %{}, fn spec, acc ->
      case Keyword.get(spec, :default) do
        nil -> acc
        v -> Map.put(acc, Keyword.get(spec, :name), v)
      end
    end)
    Module.put_attribute(env.module, :defaults, defaults)

    # Defined in case category does not defines any attribute
    last_clauses = [{
      quote do
        def __fetch_this__(entity, name), do: raise FunctionClauseError
      end,
      quote do
        def __set__(entity, name, _), do: raise FunctionClauseError
      end
    }]
    clauses = Enum.reduce(specs, last_clauses, fn spec, acc ->
      name = Keyword.get(spec, :name)
      fetcher = fetcher(name, Keyword.get(spec, :get), Keyword.get(spec, :default))
      setter = setter(name, Keyword.get(spec, :set), Keyword.get(spec, :check))

      acc = [ {fetcher, setter} | acc ]

      case Keyword.get(spec, :alias) do
	      nil -> acc
	      alias_ -> [ {getter_alias(name, alias_), setter_alias(name, alias_)} | acc ]
      end
    end)

    for {fetcher, _} <- clauses do
      Module.eval_quoted(env.module, fetcher)
    end

    for {_, setter} <- clauses do
      Module.eval_quoted(env.module, setter)
    end
  end

  @doc false
  def __add_action_spec__(env, {name, _, _, _}=spec) do
    # Add to related category
    actions = Module.get_attribute(env.module, :actions)
    if List.keymember?(actions, name, 0) do
      raise OCCI.Error, {422, "Action '#{name}' already defined"}
    else
      modname = action_module(env, name)
      Module.put_attribute(env.module, :action_mods, [ {name, modname} | Module.get_attribute(env.module, :action_mods) ])
      Module.put_attribute(env.module, :actions, [ spec | actions ])
    end
  end

  @doc false
  def __def_actions__(env) do
    model = Module.get_attribute(env.module, :model)
    specs = Module.get_attribute(env.module, :actions)

    for {name, args, opts, do_block} <- specs do
      {scheme, term} = action_id(name, opts, env)
      category = :"#{scheme}##{term}"
      modname = Keyword.get(Module.get_attribute(env.module, :action_mods), name)
      opts = [
        {:scheme, scheme},
        {:term, term},
        {:model, Module.get_attribute(env.module, :model)},
        {:related, Module.get_attribute(env.module, :category)},
        {:related_mod, env.module}
        | opts
      ]

      if do_block do
        case args do
          [_, _] -> :ok
          nil -> :ok
          _ ->
            # In case do_block is defined, signature must include 2 arguments
            # and only two: entity + attributes
            raise OCCI.Error, {422, "Action defines its body, signature must be of arity 2"}
        end
      end

      # Create action module
      ast = quote do
        defmodule unquote(modname) do
          use OCCI.Action, unquote(opts)
        end
      end
      Module.eval_quoted(env.module, ast)

      # Create action function in category
      ast = quote do
        def unquote(name)(entity, attrs) do
          action = unquote(modname).new(attrs)
          unquote(model).__exec__(action, entity)
        end
      end
      Module.eval_quoted(env.module, ast)

      # Create action implementation function if any
      if do_block do
        do_action = :"__#{category}__"
        ast = quote do
          def unquote(do_action)(unquote_splicing(args)) do
            unquote(do_block)
          end
        end
        Module.eval_quoted(env.module, ast)
      end
    end

    ast = quote do
      def __actions__, do: @action_mods
    end
    Module.eval_quoted(env.module, ast)
  end

  @doc false
  def __to_atom__(nil), do: nil
  def __to_atom__(s), do: :"#{s}"

  @doc false
  def __parse_category__(name) do
    case String.split("#{name}", "#") do
      [scheme, term] -> {:"#{scheme}", :"#{term}"}
      _ -> raise OCCI.Error, {422, "Invalid category: #{name}"}
    end
  end

  @doc false
  def __valid_scheme__(scheme) do
    case String.split("#{scheme}", "#") do
      [s] -> :"#{s}"
      [s, ""] -> :"#{s}"
      _ -> raise "Invalid syntax for scheme: #{scheme}"
    end
  end

  @doc false
  def __merge_modules__(mod1, mod2) when is_list(mod1) and is_list(mod2) do
    Module.concat(mod1 ++ mod2)
  end
  def __merge_modules__(mod1, mod2) when is_atom(mod1), do: __merge_modules__(Module.split(mod1), mod2)
  def __merge_modules__(mod1, mod2) when is_atom(mod2), do: __merge_modules__(mod1, Module.split(mod2))

  ###
  ### Priv
  ###
  defp action_module(env, name) do
    Module.concat([env.module, Actions, Macro.camelize("#{name}")])
  end

  defp action_id(name, opts, env) do
    scheme = Keyword.get_lazy(opts, :scheme, fn ->
      Module.get_attribute(env.module, :scheme)
    end)
    term = Keyword.get_lazy(opts, :term, fn ->
      Module.get_attribute(env.module, :term)
    end)
    {:"#{scheme}/#{term}#", :"#{name}"}
  end

  defp fetcher(name, nil, default) do
    quote do
      def __fetch_this__(entity, unquote(name)) do
        {:ok, Map.get(entity.attributes, unquote(name), unquote(default))}
      end
    end
  end
  defp fetcher(name, custom, _) do
    quote do
      def __fetch_this__(entity, unquote(name)) do
        {:ok, unquote(custom).(entity)}
      end
    end
  end

  defp getter_alias(name, alias_) do
    quote do
      def __fetch_this__(entity, unquote(alias_)), do: __fetch_this__(entity, unquote(name))
    end
  end

  defp setter(name, nil, nil) do
    quote do
      def __set__(entity, unquote(name), _) do
        raise OCCI.Error, {422, "Attribute #{unquote(name)} is unmutable"}
      end
    end
  end
  defp setter(name, nil, {typemod, opts}) do
    quote do
      def __set__(entity, unquote(name), value) do
	      casted = try do
		               unquote(typemod).cast(value, unquote(opts))
		             rescue
		               e in FunctionClauseError ->
		                 raise OCCI.Error, {422, "Invalid value: #{inspect value}"}
		             end
	      attributes = Map.put(entity.attributes, unquote(name), casted)
	      %{ entity | attributes: attributes }
      end
    end
  end
  defp setter(name, custom, _) do
    quote do
      def __set__(entity, unquote(name), value) do
	      unquote(custom).(entity, value)
      end
    end
  end

  defp setter_alias(name, alias_) do
    quote do
      def __set__(entity, unquote(alias_), value), do: __set__(entity, unquote(name), value)
    end
  end
end
