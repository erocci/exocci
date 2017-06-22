defmodule OCCI.Types do

  defmodule String do
    def cast(v) do
      try do
	"#{v}"
      rescue Protocol.UndefinedError ->
	  "#{inspect v}"
      end
    end
  end

  defmodule URI do
    defdelegate cast(v), to: OCCI.Types.String
  end
end
