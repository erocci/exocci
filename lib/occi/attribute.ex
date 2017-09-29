defmodule OCCI.Attribute do
  @moduledoc """
  Handle attribute specifications
  """
  alias OCCI.Types

  @doc """
  Generate attribute specification
  """
  @spec spec(name :: charlist() | String.t | atom, opts :: list) :: opts :: []
  def spec(name, opts) do
    Enum.map(opts, fn
      {:type, type} -> {:check, Types.check(type)}
      {:required, required} when is_boolean(required) -> {:required, required}
      {:description, description} when is_binary(description) or is_list(description) -> {:description, description}
      {:mutable, mutable} when is_boolean(mutable) -> {:mutable, mutable}
      {k, v} -> {k, v}
    end)
    |> Keyword.put(:name, :"#{name}")
  end

  @doc false
  # Returns list of required modules
  def __required__({_, opts}, env) do
    Enum.reduce(opts, [], fn
      {:type, type}, acc -> OCCI.Types.__requires__(Macro.expand(type, env)) ++ acc
      _, acc -> acc
    end)
  end
end
