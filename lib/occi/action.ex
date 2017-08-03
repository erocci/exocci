defmodule OCCI.Action do
  defmacro __using__(opts) do
    opts = [ {:type, :action} | opts ]

    quote do
      use OCCI.Category, unquote(opts)
      @before_compile OCCI.Action

      def new(attributes) do
        action = %{ attributes: %{} }
        action = Enum.reduce(attributes, action, fn {key, value}, acc ->
          set(acc, key, value)
        end)

        missing = Enum.reduce(required(), [], fn id, acc ->
          case get(action, id) do
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

      def get(action, key) do
        try do
          __MODULE__.__get__(action, key)
        rescue e in UndefinedFunctionError ->
            raise OCCI.Error, {422, "Undefined attribute: #{key}"}
          e in UndefinedFunctionError ->
            raise OCCI.Error, {422, "Undefined attribute: #{key}"}
        end
      end

      def set(action, key, value) do
        try do
          __MODULE__.__set__(action, key, value)
        rescue e in UndefinedFunctionError ->
            raise OCCI.Error, {422, "Undefined attribute: #{key}"}
          e in UndefinedFunctionError ->
            raise OCCI.Error, {422, "Undefined attribute: #{key}"}
        end
      end
    end
  end

  defmacro __before_compile__(_opts) do
    OCCI.Category.Helpers.__def_attributes__(__CALLER__)
  end
end
