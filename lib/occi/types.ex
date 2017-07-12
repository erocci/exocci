defmodule OCCI.Types do
  defmacro __using__(_opts) do
    quote do
      @behaviour OCCI.Types
    end
  end

  @callback cast(data :: any, opts :: term) :: any

  @doc """
  Return {module, opts}
  """
  def check(type) when is_list(type) do
    {OCCI.Types.Enum, type}
  end
  def check({type, opts}) do
    case Code.ensure_loaded(type) do
      {:module, _} ->
	if function_exported?(type, :cast, 1) || function_exported?(type, :cast, 2) do
	  {type, opts}
	else
	  raise OCCI.Error, {422, "#{type} do not implements OCCI.Types behaviour"}
	end
      _ -> raise OCCI.Error, {422, "Unknown OCCI type: #{type}"}
    end
  end
  def check(type) when is_atom(type) do
    check({type, []})
  end
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

defmodule OCCI.Types.Integer do
  use OCCI.Types
  def cast(v, _) when is_integer(v) do
    v
  end
  def cast(v, _) when is_binary(v) do
    case Integer.parse(v) do
      :error -> raise OCCI.Error, {422, "Invalid integer: #{v}"}
      {i, ""} -> i
      _ -> raise OCCI.Error, {422, "Invalid integer: #{v}"}
    end
  end
end

defmodule OCCI.Types.Float do
  use OCCI.Types
  def cast(v, _) when is_float(v) do
    v
  end
  def cast(v, _) when is_binary(v) do
    case Float.parse(v) do
      :error -> raise OCCI.Error, {422, "Invalid float: #{v}"}
      {i, ""} -> i
      _ -> raise OCCI.Error, {422, "Invalid float: #{v}"}
    end
  end
end


defmodule OCCI.Types.Enum do
  use OCCI.Types
  def cast(v, values) do
    val = :"#{v}"
    if val in values do
      val
    else
      raise OCCI.Error, {422, "Invalid value: #{v} not in #{inspect values}"}
    end
  end
end

defmodule OCCI.Types.CIDR do
  use OCCI.Types
  def cast(v, _) do
    case :inet.parse_address('#{v}') do
      {:ok, cidr} -> cidr
      _ -> raise OCCI.Error, {422, "Invalid CIDR: #{inspect v}"}
    end
  end
end
