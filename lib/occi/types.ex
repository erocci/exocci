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
  def cast(v, opts \\ nil)
  def cast(v, opts) when is_integer(v) do
    range(v, Keyword.get(opts, :min), Keyword.get(opts, :max))
  end
  def cast(v, opts) when is_binary(v) do
    case Integer.parse(v) do
      :error -> raise OCCI.Error, {422, "Invalid integer: #{v}"}
      {i, ""} -> range(i, Keyword.get(opts, :min), Keyword.get(opts, :max))
      _ -> raise OCCI.Error, {422, "Invalid integer: #{v}"}
    end
  end

  defp range(i, nil, nil), do: i
  defp range(i, min, nil) when i >= min, do: i
  defp range(i, nil, max) when i <= max, do: i
  defp range(i, min, max) when i >= min and i <= max, do: i
  defp range(i, min, max), do: raise OCCI.Error, {422, "Not in range(#{inspect min}, #{inspect max}): #{i}"}
end

defmodule OCCI.Types.Float do
  use OCCI.Types
  def cast(v, opts \\ nil)
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
  def cast(v, _ \\ nil) do
    try do
      case String.split("#{v}", "/") do
        [addr] ->
          case :inet.parse_address('#{addr}') do
            {:ok, cidr} when tuple_size(cidr) == 4 -> {cidr, 32}
            {:ok, cidr} when tuple_size(cidr) == 8 -> {cidr, 128}
            {:ok, }
            _ -> raise ""
          end
        [addr, netmask] ->
          case :inet.parse_address('#{addr}') do
            {:ok, cidr} when tuple_size(cidr) == 4 ->
              {cidr, OCCI.Types.Integer.cast(netmask, min: 0, max: 32)}
            {:ok, cidr} when tuple_size(cidr) == 8 ->
              {cidr, OCCI.Types.Integer.cast(netmask, min: 0, max: 128)}
            _ -> raise ""
          end
      end
    rescue _ ->
        raise OCCI.Error, {422, "Invalid CIDR: #{inspect v}"}
    end
  end
end
