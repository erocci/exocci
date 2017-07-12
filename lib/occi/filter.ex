defmodule OCCI.Filter do

  @type filter :: f_not | f_or | f_and | f_category | f_core | f_attr
  @type f_not :: {:not, filter}
  @type f_or :: {:or, [ filter ]}
  @type f_and :: [ filter ] | {:and, [ filter ]}
  @type f_category :: {:category, :atom} | {:kind, :atom} | {:mixin, :atom} | {:parent, :atom}
  @type f_core :: {:id, OCCI.Entity.id} | {:source, String.t} | {:target, String.t}
  @type f_attr :: {atom, term}

  @type t :: filter

  @doc """
  Return true if entity match filters
  """
  def match(entity, {:not, filters}) do
    not match(entity, filters)
  end
  def match(entity, {:or, filters}) when is_list(filters) do
    Enum.any?(filters, &(match(entity, &1)))
  end
  def match(entity, {:and, filters}) when is_list(filters) do
    Enum.all?(filters, &(match(entity, &1)))
  end
  def match(entity, filters) when is_list(filters) do
    Enum.all?(filters, &(match(entity, &1)))
  end
  def match(entity, {:category, category}) do
    match(entity, {:or, [parent: category, kind: category, mixin: category]})
  end
  def match(entity, {:kind, value}), do: entity[:kind] == value
  def match(entity, {:parent, value}), do: entity[:parent] == value
  def match(entity, {:mixin, value}) do
    value in (entity[:mixins] || [])
  end
  def match(entity, {:id, value}), do: entity[:id] == value
  def match(entity, {:source, value}), do: entity[:source][:location] == value
  def match(entity, {:target, value}), do: entity[:target][:location] == value
  def match(entity, {key, value}) when is_atom(key) do
    entity[:attributes][key] == value
  end
  def match(entity, {keys, value}) when is_list(keys) do
    get_in(entity[:attributes], keys) == value
  end
end
