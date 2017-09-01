defmodule OCCI.Category.Helpers do
  @moduledoc """
  Collection of functions for compiling OCCI category modules.
  """

  @doc false
  def __gen_doc__(_env) do
  end

  @doc false
  def __def_attributes__(env) do
    specs = Enum.reduce(Module.get_attribute(env.module, :attributes), [], fn spec, acc ->
      case Keyword.get(spec, :type) do
	      nil -> [ spec | acc ]
	      type -> [ Keyword.put(spec, :check, OCCI.Types.check(type)) | acc ]
      end
    end)

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

    clauses = Enum.reduce(specs, [], fn spec, acc ->
      name = Keyword.get(spec, :name)
      getter = getter(name, Keyword.get(spec, :get), Keyword.get(spec, :default))
      setter = setter(name, Keyword.get(spec, :set), Keyword.get(spec, :check))

      acc = [ {getter, setter} | acc ]

      case Keyword.get(spec, :alias) do
	      nil -> acc
	      alias_ -> [ {getter_alias(name, alias_), setter_alias(name, alias_)} | acc ]
      end
    end)

    for {getter, _} <- clauses do
      Module.eval_quoted(env.module, getter)
    end

    for {_, setter} <- clauses do
      Module.eval_quoted(env.module, setter)
    end
  end

  @doc false
  def __add_action_spec__(env, {name, _, _, _}=spec) do

    # Add to related category
    actions = Module.get_attribute(env.module, :actions)
    #IO.puts("ACTIONS: #{inspect name} in #{inspect actions} ?")
    if List.keymember?(actions, name, 0) do
      raise OCCI.Error, {422, "Action '#{name}' already defined"}
    else
      Module.put_attribute(env.module, :actions, [ spec | actions ])
    end
  end

  @doc false
  def __def_actions__(env) do
    model = Module.get_attribute(env.module, :model)
    specs = Module.get_attribute(env.module, :actions)

    for {name, args, opts, do_block} <- specs do
      category = action_id(name, opts, env)
      modname = Module.concat([env.module, Actions, Macro.camelize("#{name}")])
      opts = [
        {:name, category},
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
            unquote(do_block[:do])
          end
        end
        Module.eval_quoted(env.module, ast)
      end
    end
  end

  @doc false
  def __mod_name__(name, args, env) do
    case Keyword.get(args, :alias) do
      nil ->
	      mod_encode("#{name}", env)
      {:__aliases__, _, _}=aliases ->
	      Module.concat([env.module, Macro.expand(aliases, env)])
    end
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

  ###
  ### Priv
  ###
  defp action_id(name, opts, env) do
    case Keyword.get(opts, :category) do
		  nil ->
		    scheme = Module.get_attribute(env.module, :scheme)
		    term = Module.get_attribute(env.module, :term)
		    :"#{scheme}/#{term}/action##{name}"
		  cat ->
		    :"#{cat}"
		end
  end

  defp mod_encode(name, env) do
    case String.split(name, "#") do
      [_scheme, term] ->
        categories = Map.merge(Module.get_attribute(env.module, :kinds), Module.get_attribute(env.module, :mixins))
        newmod = Module.concat([env.module, Macro.camelize(term)])
        exist = Enum.any?(categories, fn {_, mod} ->
          Module.concat([mod]) == newmod
        end)
        if exist do
          raise OCCI.Error, {422, "Category with term '#{Macro.camelize(term)}' already exists in this model, please alias it."}
        else
          newmod
        end
      _ -> raise OCCI.Error, {422, "Invalid category : #{name}"}
    end
  end

  defp getter(name, nil, default) do
    quote do
      def __get__(entity, unquote(name)) do
	      Map.get(entity.attributes, unquote(name), unquote(default))
      end
    end
  end
  defp getter(name, custom, _) do
    quote do
      def __get__(entity, unquote(name)) do
	      unquote(custom).(entity)
      end
    end
  end

  defp getter_alias(name, alias_) do
    quote do
      def __get__(entity, unquote(alias_)), do: __get__(entity, unquote(name))
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
