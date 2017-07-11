defmodule OCCI.Category.Helpers do

  def def_attributes(env) do
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
    Module.eval_quoted env.module, ast

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

  def def_actions(env) do
    for {name, [entity_arg, attrs_arg], opts, do_block} <- Module.get_attribute(env.module, :actions) do
      category = case Keyword.get(opts, :category) do
		               nil ->
		                 scheme = Module.get_attribute(env.module, :scheme)
		                 term = Module.get_attribute(env.module, :term)
		                 :"#{scheme}/#{term}/action##{name}"
		               cat ->
		                 :"#{cat}"
		             end

      modname = OCCI.Category.Helpers.mod_name(category, opts, env)
      opts = [
        {:name, category},
        {:model, Module.get_attribute(env.module, :model)},
        {:related, Module.get_attribute(env.module, :category)}
        | opts
      ]
      do_name = :'do_#{name}'

      ast = quote do
        defmodule unquote(modname) do
          use OCCI.Action, unquote(opts)
        end

        def unquote(name)(unquote(entity_arg)=entity, unquote(attrs_arg)=attrs) do
          action = unquote(modname).new(attrs)
          unquote(do_name)(unquote(entity_arg), action)
        end

        def unquote(do_name)(unquote(entity_arg), unquote(attrs_arg)) do
          unquote(do_block[:do])
        end
      end
      Module.eval_quoted(env.module, ast)
    end
  end

  def mod_name(name, args, env) do
    case Keyword.get(args, :alias) do
      nil ->
	      mod_encode("#{name}") |> to_atom
      {:__aliases__, _, _}=aliases ->
	      Module.concat([env.module, Macro.expand(aliases, env)])
    end
  end

  def mod_encode(name) do
    URI.encode(name, &URI.char_unreserved?/1)
  end

  def to_atom(nil), do: nil
  def to_atom(s), do: :"#{s}"

    def getter(name, nil, default) do
    quote do
      def __get__(entity, unquote(name)) do
	      Map.get(entity.attributes, unquote(name), unquote(default))
      end
    end
  end
  def getter(name, custom, _) do
    quote do
      def __get__(entity, unquote(name)) do
	      unquote(custom).(entity)
      end
    end
  end

  def getter_alias(name, alias_) do
    quote do
      def __get__(entity, unquote(alias_)), do: __get__(entity, unquote(name))
    end
  end

  def setter(name, nil, nil) do
    raise OCCI.Error, {422, "Invalid attribute specification: #{name}. You must specifiy either type or custom setter"}
  end
  def setter(name, nil, {typemod, opts}) do
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
  def setter(name, custom, _) do
    quote do
      def __set__(entity, unquote(name), value) do
	      unquote(custom).(entity, value)
      end
    end
  end

  def setter_alias(name, alias_) do
    quote do
      def __set__(entity, unquote(alias_), value), do: __set__(entity, unquote(name), value)
    end
  end

  def parse_category(name) do
    case String.split("#{name}", "#") do
      [scheme, term] -> {:"#{scheme}", :"#{term}"}
      _ -> raise OCCI.Error, {422, "Invalid category: #{name}"}
    end
  end
end
