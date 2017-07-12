defmodule OCCI.Node do
  require Record

  @type location :: String.t
  @type user :: String.t
  @type group :: String.t
  @type owner :: {user, group} | nil
  @type serial :: String.t | nil
  @type data :: OCCI.Entity.t | OCCI.Collection.t

  Record.defrecord :node, [location: nil, owner: {nil, nil}, serial: nil, data: nil]
end
