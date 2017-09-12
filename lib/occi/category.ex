defmodule OCCI.Category do
  alias OCCI.Category.Helpers
  alias OCCI.Attribute

  defmacro __using__(opts) do
    name = Keyword.get_lazy(opts, :name,
      fn -> raise "Missing argument: name" end)
    model = Keyword.get_lazy(opts, :model,
      fn -> raise "Missing argument: model" end)
    title = Keyword.get_lazy(opts, :title, fn ->
      case Keyword.get(opts, :type) do
	      :kind -> "Kind #{name}"
	      :mixin -> "Mixin #{name}"
        :action -> "Action #{name}"
	      _ -> "Category #{name}"
      end
    end)
    attr_specs = Keyword.get(opts, :attributes, [])
    {scheme, term} = Helpers.__parse_category__(name)

    Module.put_attribute(__CALLER__.module, :attributes, [])
    Module.put_attribute(__CALLER__.module, :required, [])

    quote do
      require OCCI.Category
      import OCCI.Category
      alias OCCI.Attribute

      @model unquote(model)

      @category unquote(name)
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
      def required, do: @required

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

  defmacro action({name, _, [_, _]=args}, opts, do_block) do
    # action with arguments, options and do_block
    Helpers.__add_action_spec__(__CALLER__, {name, args, opts, do_block})
  end
  defmacro action({_, _, args}, _, _do_block) do
    raise "Action signature expects 2 arguments, found #{length(args)}"
  end

  defmacro action({id, _, args}, [do: _]=do_block) do
    # action without options but with arguments and body: overriding implementation,
    # can not redefine options
    {category, name} = case id do
                         {:., _, [cat]} ->
                           {_scheme, term} = Helpers.__parse_category__(cat)
                           {cat, term}
                         id when is_atom(id) -> id
                       end
    opts = [category: category]
    Helpers.__add_action_spec__(__CALLER__, {name, args, opts, do_block})
  end
  defmacro action({name, _, nil}, opts) when is_list(opts) do
    # action without arguments but options
    Helpers.__add_action_spec__(__CALLER__, {name, nil, opts, nil})
  end
end
