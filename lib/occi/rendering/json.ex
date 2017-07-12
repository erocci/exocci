defmodule OCCI.Rendering.JSON do
  def parse(model, data) when is_binary(data) do
    model.new(Poison.decode!(data, keys: :atoms!))
  end
  def parse(model, data) when is_map(data) do
    model.new(data)
  end
end
