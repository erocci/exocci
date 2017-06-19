defmodule OCCI.Mixin do
  defmacro __using__(opts) do
    depends = Keyword.get(opts, :depends, [])
    applies = Keyword.get(opts, :applies, [])
    model = Keyword.get_lazy(opts, :model, fn -> raise "Missing argument: model" end)

    quote do
      @mixin __MODULE__
      @depends unquote(depends)
      @applies unquote(applies)
      @model unquote(model)
    end
  end
end
