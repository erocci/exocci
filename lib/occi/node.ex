defmodule OCCI.Node do
  @moduledoc """
  Structure for entities metadata
  """
  @type location :: String.t

  defstruct [:location, :owner, :serial, :defined_in, :created_in]

  @type t :: %OCCI.Node{
    location: location,
    owner: {String.t, String.t} | nil,
    serial: String.t | nil,
    defined_in: atom,
    created_in: atom}
end
