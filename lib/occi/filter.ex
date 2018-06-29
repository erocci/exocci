defmodule OCCI.Filter do
  @moduledoc """
  Defines filters for looking up OCCI datastore
  """

  @type filter :: f_not | f_or | f_and | f_category | f_core | f_attr
  @type f_not :: {:not, filter}
  @type f_or :: {:or, [filter]}
  @type f_and :: [filter] | {:and, [filter]}
  @type f_category :: {:category, :atom} | {:kind, :atom} | {:mixin, :atom} | {:parent, :atom}
  @type f_core :: {:id, OCCI.Entity.id()} | {:source, String.t()} | {:target, String.t()}
  @type f_attr :: {atom, term}

  @type t :: filter

  @doc """
  Return true if entity match filters
  """
  def match(entity, {:not, filters}) do
    not match(entity, filters)
  end

  def match(entity, {:or, filters}) when is_list(filters) do
    Enum.any?(filters, &match(entity, &1))
  end

  def match(entity, {:and, filters}) when is_list(filters) do
    Enum.all?(filters, &match(entity, &1))
  end

  def match(entity, filters) when is_list(filters) do
    Enum.all?(filters, &match(entity, &1))
  end

  def match(entity, {:category, category}) do
    match(entity, {:or, [parent: category, kind: category, mixin: category]})
  end

  def match(entity, {:kind, value}), do: match_category(value, entity[:kind])
  def match(entity, {:parent, value}), do: match_category(value, entity[:parent])
  def match(entity, {:mixin, value}), do: match_categories(value, entity[:mixins] || [])
  def match(entity, {:id, value}), do: entity[:id] == value
  def match(entity, {:source, value}), do: entity[:source][:location] == value
  def match(entity, {:target, value}), do: entity[:target][:location] == value

  def match(entity, {key, value}) when is_atom(key) do
    entity[:attributes][key] == value
  end

  def match(entity, {keys, value}) when is_list(keys) do
    get_in(entity[:attributes], keys) == value
  end

  ###
  ### Priv
  ###
  defp match_category(val, cat), do: match_categories(val, [cat])

  defp match_categories(_, []), do: false

  defp match_categories(val, [cat | rest]) do
    res =
      try do
        Module.safe_concat([cat]) == Module.safe_concat([val])
      rescue
        ArgumentError ->
          cat.category() == :"#{val}"
      end

    if res, do: true, else: match_categories(val, rest)
  end
end
