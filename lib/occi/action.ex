defmodule OCCI.Action do
  defmacro __using__(opts) do
    name = Keyword.get(opts, :name)
    related = Keyword.get(opts, :related)
    related_mod = Keyword.get(opts, :related_mod)
    opts = [ {:type, :action} | opts ]

    quote do
      use OCCI.Category, unquote(opts)
      alias OCCI.Action

      @doc """
      Create an instance of #{unquote(name)}.
      """
      def new(attributes) do
        action = %{
          id: @category,
          mod: __MODULE__,
          related: unquote(related),
          related_mod: unquote(related_mod),
          attributes: %{}
        }
        action = Enum.reduce(attributes, action, fn {key, value}, acc ->
          Action.set(acc, key, value)
        end)

        missing = Enum.reduce(__required__(), [], fn id, acc ->
          case Action.get(action, id) do
            nil -> [ id | acc ]
            _ -> acc
          end
        end)
        case missing do
          [] -> action
          ids ->
            names = Enum.join(ids, " ")
            raise OCCI.Error, {422, "Missing attributes: #{names}"}
        end
      end

      @before_compile OCCI.Action
    end
  end

  defmacro __before_compile__(_opts) do
    OCCI.Category.Helpers.__def_attributes__(__CALLER__)

    quote do
      @doc false
      def __defaults__, do: @defaults
    end
  end

  @doc """
  Returns action category id
  """
  def id(%{ id: id }), do: id

  @doc """
  Returns action related category
  """
  def related(%{ related: related }), do: related

  @doc """
  Return casted attributes, with default values for required ones, if necessary
  """
  def attributes(%{ mod: mod, attributes: attrs }) do
    Enum.reduce(mod.__required__(), attrs, &(Map.put_new(&2, &1, Map.get(mod.__defaults__(), &1))))
  end

  @doc """
  Get an attribute value, or its default value if not set
  """
  def get(%{ mod: mod }=action, key) do
    try do
      mod.__get__(action, key)
    rescue FunctionClauseError ->
        raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      UndefinedFunctionError ->
        raise OCCI.Error, {422, "Undefined attribute: #{key}"}
    end
  end

  @doc """
  Set an action attribute
  """
  def set(%{ mod: mod }=action, key, value) do
    try do
      mod.__set__(action, key, value)
    rescue FunctionClauseError ->
        raise OCCI.Error, {422, "Undefined attribute: #{key}"}
      UndefinedFunctionError ->
        raise OCCI.Error, {422, "Undefined attribute: #{key}"}
    end
  end

  @doc false
  def __related_mod__(%{ related_mod: mod }), do: mod
end
