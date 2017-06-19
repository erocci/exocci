defmodule OCCI.Model.Helpers do

  defmacro gen_set_clauses(specs) do
    quote bind_quoted: [specs: specs] do
      for {name, spec} <- specs do
        def set_attr(entity, unquote(name), value) do
          Map.put(entity, unquote(name), value)
        end
      end
    end
  end

end
