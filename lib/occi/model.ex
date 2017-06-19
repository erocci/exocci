defmodule OCCI.Model do
  require OCCI.Model.Core
  
  @doc false
  defmacro __using__(_) do
    user_mixins = :"#{__CALLER__.module}.UserMixins"
    quote do
      require OCCI.Model

      import OCCI.Model

      defmodule unquote(user_mixins) do
        def mixins, do: MapSet.new
      end

      def kinds, do: @kinds || MapSet.new

      def mixins do
        MapSet.union(@mixins, unquote(user_mixins).mixins)
      end

      def mixin(name) do
        mixins = MapSet.put(unquote(user_mixins).mixins, :"#{name}")
        def_user_mixins(unquote(user_mixins), mixins)
      end

      def del_mixin(name) do
        mixins = unquote(user_mixins).mixins |> MapSet.delete(:"#{name}")
        def_user_mixins(unquote(user_mixins), mixins)
      end
    end
  end

  defmacro kind(name, args) do
    name = :"#{name}"
    parent = case Keyword.get(args, :parent, nil) do
	       nil -> OCCI.Model.Core.kind_resource
	       p -> p
	     end    
    attributes = Keyword.get(args, :attributes, [])

    model = __CALLER__.module
    kinds = Module.get_attribute(model, :kinds) || MapSet.new
    Module.put_attribute(model, :kinds, MapSet.put(kinds, name))

    quote do
      defmodule unquote(name) do
        use OCCI.Kind,
          parent: :"#{unquote(parent)}",
          model: unquote(model),
          attributes: unquote(attributes)
      end
    end
  end

  defmacro def_user_mixins(mod, mixins) do
    quote do
      defmodule unquote(mod) do
        def mixins, do: unquote(mixins)
      end
    end
  end
end
