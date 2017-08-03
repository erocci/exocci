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
        :action -> "Action #{name}"
	      _ -> "Category #{name}"
      end
    end)
    attr_specs = Keyword.get(opts, :attributes, [])
    {scheme, term} = OCCI.Category.Helpers.__parse_category__(name)

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

      for {name, spec} <- unquote(attr_specs) do
	      name = :"#{name}"
	      spec = [ {:name, name} | spec ]
	      Module.put_attribute(__MODULE__, :attributes,
	        [ spec | Module.get_attribute(__MODULE__, :attributes) ])

	      if Keyword.get(spec, :required, false) do
	        Module.put_attribute(__MODULE__, :required,
	          [ name | Module.get_attribute(__MODULE__, :required) ])
	      end
      end

      def category, do: @category
      def scheme, do: :"#{@scheme}#"
      def term, do: @term
      def title, do: @title
      def required, do: @required
    end
  end

  defmacro attribute(name, opts) do
    name = :"#{name}"
    spec = [ {:name, name} | opts ]

    ast = quote do
      Module.put_attribute(__MODULE__, :attributes,
	      [ unquote(spec) | Module.get_attribute(__MODULE__, :attributes) ])
    end
    Module.eval_quoted(__CALLER__, ast)

    if Keyword.get(opts, :required, false) do
      ast = quote do
	      Module.put_attribute(__MODULE__, :required,
	        [ unquote(name) | Module.get_attribute(__MODULE__, :required) ])
      end
      Module.eval_quoted __CALLER__, ast
    end
  end

  defmacro action({name, _, [_, _]=args}, opts, do_block) do
    spec = {:"#{name}", args, opts, do_block}
    Module.put_attribute(__CALLER__.module, :actions,
      [ spec | Module.get_attribute(__CALLER__.module, :actions) ])
  end
  defmacro action({_, _, args}, _, _) do
    raise "Action signature expects 2 arguments, found #{length(args)}"
  end
end
