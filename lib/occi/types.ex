defmodule OCCI.Types do
  defmacro __using__(_opts) do
    quote do
      @behaviour OCCI.Types

      def check_opts(_opts), do: true

      defoverridable [check_opts: 1]
    end
  end

  @callback check_opts(opts :: any) :: boolean | {true, canonical_opts :: any}
  @callback cast(data :: any, opts :: term) :: any

  @doc """
  Return {module, opts}
  """
  def check(type) when is_list(type) do
    {OCCI.Types.Enum, type}
  end
  def check({mod, opts}) do
    case Code.ensure_loaded(mod) do
      {:module, _} ->
	      if function_exported?(mod, :cast, 1) || function_exported?(mod, :cast, 2) do
          case mod.check_opts(opts) do
            false -> raise OCCI.Error, {422, "Invalid options for #{mod}: #{inspect opts}"}
            true -> {mod, opts}
            {true, opts} -> {mod, opts}
          end
	      else
	        raise OCCI.Error, {422, "#{mod} do not implements OCCI.Types behaviour"}
	      end
      _ -> raise OCCI.Error, {422, "Unknown OCCI type: #{mod}"}
    end
  end
  def check(mod) when is_atom(mod) do
    check({mod, []})
  end
end

defmodule OCCI.Types.String do
  use OCCI.Types

  def check_opts(opts) do
    try do
      case Keyword.get(opts, :match, nil) do
        nil -> true
        r when is_binary(r) -> {true, [match: quote do Regex.compile!(unquote(r)) end]}
        _ -> false
      end
    rescue FunctionClauseError -> false
    end
  end

  def cast(v, opts \\ []) do
    case Keyword.get(opts, :match, nil) do
      nil ->
        try do
          "#{v}"
        rescue Protocol.UndefinedError ->
	          "#{inspect v}"
        end
      r ->
        if Regex.match?(r, v) do
          v
        else
          raise OCCI.Error, {422, "#{inspect v} does not match #{inspect r}"}
        end
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

  def check_opts(model) when is_atom(model), do: true
  def check_opts(_), do: false

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

  def check_opts(_), do: true

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

defmodule OCCI.Types.Boolean do
  use OCCI.Types

  def cast(v, _) when is_boolean(v), do: true
  def cast(v, _) do
    raise OCCI.Error, {422, "Invalid boolean: #{inspect v}"}
  end
end

defmodule OCCI.Types.Enum do
  use OCCI.Types

  def check_opts(values) when is_list(values), do: true
  def check_opts(_), do: false

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
