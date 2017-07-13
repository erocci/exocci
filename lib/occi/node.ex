defmodule OCCI.Node do
  @moduledoc """
  Defines struct, getter and setter for entity's internal metadata
  """
  @type location :: String.t

  defstruct [:location, :owner, :serial, :model]

  @type t :: %OCCI.Node{location: location, owner: {String.t, String.t} | nil, serial: String.t | nil, model: atom}
end
