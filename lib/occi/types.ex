defmodule OCCI.Types do
  defmacro __using__(_opts) do
    quote do
      @behaviour OCCI.Types
    end
  end

  @callback cast(data :: any, opts :: term) :: any
end

defmodule OCCI.Types.String do
  use OCCI.Types
  
  def cast(v, _opts \\ nil) do
    try do
      "#{v}"
    rescue Protocol.UndefinedError ->
	"#{inspect v}"
    end
  end
end

defmodule OCCI.Types.URI do
  use OCCI.Types
  defdelegate cast(v), to: OCCI.Types.String
  defdelegate cast(v, opts), to: OCCI.Types.String
end

defmodule OCCI.Types.Kind do
  use OCCI.Types
  def cast(v, model) do
    kind = :"#{v}"
    if model.kind?(kind) do
      kind
    else
      raise OCCI.Error, {422, "Invalid kind: #{v}"}
    end
  end
end
