defmodule OCCI.Category do
  @moduledoc """
  Use this module for building OCCI Category module.

  Not intended to be used directly by user, but through `OCCI.Kind` / `OCCI.Mixin` modules
  or `OCCI.Model.kind` and `OCCI.Model.Mixin` macros.
  """

  alias OCCI.Category.Helpers
  alias OCCI.Attribute

  @doc """
  Requires the following arguments:
  * `scheme` (atom): category scheme
  * `term` (atom): category term
  * `model` (alias | atom): model in which category is defined
  """
  defmacro __using__(opts) do
    scheme = Keyword.get_lazy(opts, :scheme,
      fn -> raise "Missing argument: scheme" end)
    term = Keyword.get_lazy(opts, :term,
      fn -> raise "Missing argument: term" end)
    category = :"#{scheme}##{term}"
    model = Keyword.get_lazy(opts, :model,
      fn -> raise "Missing argument: model" end)
    title = Keyword.get_lazy(opts, :title, fn ->
      case Keyword.get(opts, :type) do
	      :kind -> "Kind #{category}"
	      :mixin -> "Mixin #{category}"
        :action -> "Action #{category}"
	      _ -> "Category #{category}"
      end
    end)
    occi_type = Keyword.get(opts, :type)
    attr_specs = Keyword.get(opts, :attributes, [])
    for req <- Enum.flat_map(attr_specs, &(Attribute.__required__(&1, __CALLER__))) do
      Module.eval_quoted(__CALLER__, {:require, [], [quote do unquote(req) end]})
    end

    Module.put_attribute(__CALLER__.module, :attributes, [])
    Module.put_attribute(__CALLER__.module, :required, [])
    Module.put_attribute(__CALLER__.module, :compile_requires, [])

    quote do
      require OCCI.Category
      import OCCI.Category
      alias OCCI.Attribute

      @model unquote(model)
      @occi_type unquote(occi_type)

      @category unquote(category)
      @scheme unquote(scheme)
      @term unquote(term)
      @title unquote(title)

      for {name, spec} <- unquote(attr_specs) do
	      spec = Attribute.spec(name, spec)
	      Module.put_attribute(__MODULE__, :attributes,
	        [ spec | Module.get_attribute(__MODULE__, :attributes) ])

	      if Keyword.get(spec, :required, false) do
	        Module.put_attribute(__MODULE__, :required,
	          [ :"#{name}" | Module.get_attribute(__MODULE__, :required) ])
	      end
      end

      def category, do: @category
      def scheme, do: :"#{@scheme}#"
      def term, do: @term
      def title, do: @title

      @doc false
      def __required__, do: @required

      @doc false
      def __occi_type__, do: @occi_type

      @doc false
      def __specs__, do: @attributes

      @before_compile OCCI.Category
    end
  end

  defmacro __before_compile__(_opts) do
    :ok
  end

  defmacro attribute(name, opts) do
    ast = quote do
      Module.put_attribute(__MODULE__, :attributes,
	      [ Attribute.spec(unquote(name), unquote(opts)) | Module.get_attribute(__MODULE__, :attributes) ])
    end
    Module.eval_quoted(__CALLER__, ast)

    if Keyword.get(opts, :required, false) do
      ast = quote do
	      Module.put_attribute(__MODULE__, :required,
	        [ unquote(name) | Module.get_attribute(__MODULE__, :required) ])
      end
      Module.eval_quoted(__CALLER__, ast)
    end
  end

  defmacro action({name, _, args}, opts \\ [], do_block \\ []) do
    do_kw = Keyword.get(opts, :do)
    do_block = Keyword.get(do_block, :do)
    body = case {do_kw, do_block} do
             {nil, nil} -> nil
             {kw, nil} -> kw
             {nil, block} -> block
             {_, _} ->
               raise "Action '#{name}' defines body as keyword and as 'do' block."
           end
    if body do
      if args == nil or length(args) != 2 do
        raise "Action '#{name}' defines body, signature expects 2 arguments."
      end
    end

    Helpers.__add_action_spec__(__CALLER__, {name, args, opts, body})
  end
end
