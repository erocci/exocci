defmodule OCCI.Node do
  @moduledoc """
  Structure for entities metadata
  """
  @type location :: String.t()

  defstruct [:location, :owner, :serial, :model]

  @type t :: %OCCI.Node{
          location: location,
          owner: {String.t(), String.t()} | nil,
          serial: String.t() | nil,
          model: atom
        }
end
