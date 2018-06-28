defmodule OCCI.OrdSet do
  @moduledoc """
  A list without duplicates

  Adding an element to a set already containing this element returns
  the set unchanged.
  """

  @doc false
  def new(list \\ []), do: merge([], list)

  @doc false
  def add(set, item) do
    if item in set, do: set, else: [item | set]
  end

  @doc false
  defdelegate delete(set, item), to: List

  @doc """
  Add items from list to the set
  """
  def merge(set, list) do
    Enum.reduce(list, set, &add(&2, &1))
  end
end
