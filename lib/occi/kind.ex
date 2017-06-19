defmodule OCCI.Kind do
  defmacro __using__(
    parent: parent,
    model: model,
    attributes: _specs) do

    quote do
      @kind __MODULE__
      @parent unquote(parent)
      @model unquote(model)
    end
  end
end
