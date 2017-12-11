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
  def __def_actions__(env) do
    specs = Enum.reduce(Module.get_attribute(env.module, :actions), [], fn {name, opts}, acc ->
      {scheme, term} = action_id(name, opts, env)
      category = :"#{scheme}##{term}"
      modname = action_module(env, name)

      opts = [
        {:category, category},
        {:scheme, scheme},
        {:term, term},
        {:model, Module.get_attribute(env.module, :model)},
        {:related, Module.get_attribute(env.module, :category)},
        {:related_mod, env.module}
        | opts
      ]

      [ {name, category, modname, opts} | acc ]
    end)

    specs |> Enum.each(fn {name, category, modname, _opts} ->
      ast = quote do
        def action(unquote(category)), do: unquote(modname)
        def action(unquote(name)), do: unquote(modname)
      end
      Module.eval_quoted(env, ast)
    end)
    ast = quote do
      def action(_), do: nil
    end
    Module.eval_quoted(env, ast)

    specs |> Enum.each(fn {_name, _category, modname, opts} ->
      ast = quote do
        @action_mods unquote(modname)

        defmodule unquote(modname) do
          use OCCI.Action, unquote(opts)
        end
      end
      Module.eval_quoted(env, ast)
    end)

    ast = quote do
      def actions, do: @action_mods
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
      s = Module.get_attribute(env.module, :scheme)
      t = Module.get_attribute(env.module, :term)
      "#{s}/#{t}/action"
    end)
    term = Keyword.get(opts, :term, name)
    {:"#{scheme}", :"#{term}"}
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
