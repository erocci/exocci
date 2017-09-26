defmodule OCCI.Rendering.JSON do
  @moduledoc """
  JSON parser / renderer
  """

  @doc false
  def parse(model, data) when is_binary(data) do
    model.new(Poison.decode!(data, keys: :atoms!))
  end
  def parse(model, data) when is_map(data) do
    model.new(data)
  end

  @doc false
  def render(entity) do
    entity |>
      Map.drop([:__node__]) |>
      Poison.encode!([pretty: true])
  end
end
