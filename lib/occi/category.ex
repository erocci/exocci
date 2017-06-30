defmodule OCCI.Category do

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name,
      fn -> raise "Missing argument: name" end)
    model = Keyword.get_lazy(opts, :model,
      fn -> raise "Missing argument: model" end)
    title = Keyword.get_lazy(opts, :title, fn ->
      case Keyword.get(opts, :type) do
	:kind -> "Kind #{name}"
	:mixin -> "Mixin #{name}"
	_ -> "Category #{name}"
      end
    end)
      
    {scheme, term} = parse_category(name)

    Module.put_attribute(__CALLER__.module, :attributes, [])
    Module.put_attribute(__CALLER__.module, :required, [])

    quote do
      require OCCI.Category
      import OCCI.Category

      @model unquote(model)
      
      @category unquote(name)
      @scheme unquote(scheme)
      @term unquote(term)
      @title unquote(title)

      def category, do: @category
      def scheme, do: @scheme
      def term, do: @term
      def title, do: @title
      def required, do: @required
      
      @before_compile OCCI.Category
    end
  end

  defmacro attribute(name, opts) do
    spec = [ {:name, :"#{name}"} | opts ]

    ast = quote do
      Module.put_attribute(__MODULE__, :attributes,
	[ unquote(spec) | Module.get_attribute(__MODULE__, :attributes) ])
    end
    Module.eval_quoted(__CALLER__.module, ast)

    if Keyword.get(opts, :required, false) do
      ast = quote do
	Module.put_attribute(__MODULE__, :required,
	  [ unquote(name) | Module.get_attribute(__MODULE__, :required) ])
      end
      Module.eval_quoted __CALLER__.module, ast
    end
  end
  
  defmacro __before_compile__(_opts) do
    specs = Module.get_attribute(__CALLER__.module, :attributes)

    requires = Enum.reduce(specs, MapSet.new, fn spec, acc ->
      case Keyword.get(spec, :type) do
	nil -> acc
	type -> MapSet.put(acc, type)
      end
    end)
    ast = for mod <- requires do
      quote do
	require unquote(mod)
      end
    end
    Module.eval_quoted __CALLER__.module, ast
    
    clauses = Enum.reduce(specs, [], fn spec, acc ->
      name = Keyword.get(spec, :name)
      getter = getter(name, Keyword.get(spec, :get))
      setter = setter(name, Keyword.get(spec, :set), Keyword.get(spec, :type))
      
      acc = [ {getter, setter} | acc ]

      case Keyword.get(spec, :alias) do
	nil -> acc
	alias_ ->
	  [ {getter_alias(name, alias_), setter_alias(name, alias_)} | acc ]
      end
    end)

    for {getter, _} <- clauses do
      Module.eval_quoted(__CALLER__.module, getter)
    end

    for {_, setter} <- clauses do
      Module.eval_quoted(__CALLER__.module, setter)
    end
  end

  ###
  ### Priv
  ###
  defp parse_category(name) do
    case String.split("#{name}", "#") do
      [scheme, term] -> {:"#{scheme}#", :"#{term}"}
      _ -> raise OCCI.Error, {422, "Invalid category: #{name}"}
    end
  end

  def getter(name, nil) do
    quote do
      def __get__(entity, unquote(name)) do
	Map.get(entity.attributes, unquote(name))
      end
    end
  end
  def getter(name, custom) do
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
  def setter(name, nil, type) do
    if is_occi_type(type) do
      quote do
	def __set__(entity, unquote(name), value) do
	  attributes = Map.put(entity.attributes,
	    unquote(name), unquote(type).cast(value))
	  %{ entity | attributes: attributes }
	end
      end
    else
      raise OCCI.Error, {422, "#{type} do not implements OCCI.Types behaviour"}
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

  defp is_occi_type(type) do
    case Code.ensure_loaded(type) do
      {:module, _} -> function_exported?(type, :cast, 1) || function_exported?(type, :cast, 2)
      _ -> raise OCCI.Error, {422, "Unknown OCCI type: #{type}"}
    end
  end
end
