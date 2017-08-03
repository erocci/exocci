defmodule OCCI.Model.Infrastructure do
  @moduledoc """
  Infrastructure OCCI model
  """
  use OCCI.Model

  alias OCCI.Model.Core
  alias OCCI.Types

  kind "http://schemas.ogf.org/occi/infrastructure#compute",
    parent: Core.Resource,
    attributes: [
      "occi.compute.architecture": [
        type: [:x86, :x64],
        description: "CPU Architecture of the instance"
      ],
      "occi.compute.cores": [
        type: {Types.Integer, [min: 1]},
        description: "Number of virtual CPU cores assigned to the instance"
      ],
      "occi.compute.hostname": [
        type: Types.String,
        description: "FQDN for the instance"
      ],
      "occi.compute.share": [
        type: Types.Integer,
        description: "Relative number of CPU shares for the instance"
      ],
      "occi.compute.memory": [
        type: Types.Float,
        description: "Maximum RAM in gigabytes allocated to the instance (GB)"
      ],
      "occi.compute.state": [
        type: [:active, :inactive, :suspended, :error],
        required: true,
        mutable: false,
        description: "Current state of the instance"
      ],
      "occi.compute.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ] do
    # action start,
    #   title: "Start the instance"
    # action stop,
    #   title: "Stop the instance",
    #   attributes: [
    #     method: [type: [:graceful, :acpioff, :poweroff]]
    #   ]
    # action restart,
    #   title: "Restart the instance",
    #   attributes: [
    #     method: [type: [:graceful, :warm, :cold]]
    #   ]
    # action suspend,
    #   title: "Suspend the instance",
    #   attributes: [
    #     method: [type: [:hibernate, :suspend]]
    #   ]
    # action save,
    #   title: "Creates a snapshot of the instance",
    #   attributes: [
    #     method: [type: [:host, :deferred]],
    #     name: [type: Types.String]
    #   ]
  end

  kind "http://schemas.ogf.org/occi/infrastructure#storage",
    parent: Core.Resource,
    attributes: [
      "occi.storage.size": [
        type: Types.Float,
        required: true,
        description: "Storage size of the instance (GB)"
      ],
      "occi.storage.state": [
        type: [:online, :offline, :error],
        required: true,
        mutable: false,
        description: "Current status of the instance"
      ],
      "occi.storage.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ]

  kind "http://schemas.ogf.org/occi/infrastructure#storagelink",
    parent: Core.Link,
    attributes: [
      "occi.storagelink.deviceid": [
        type: Types.String,
        required: true,
        description: "Device identifier as defined by the OCCI service provider"
      ],
      "occi.storagelink.mountpoint": [
        type: Types.String,
        required: false,
        description: "Point to where the storage is mounted in the guest OS"
      ],
      "occi.storagelink.state": [
        type: [:active, :inactive, :error],
        mutable: false,
        description: "Current status of the instance"
      ],
      "occi.storagelink.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ]

  kind "http://schemas.ogf.org/occi/infrastructure#network",
    parent: Core.Resource,
    attributes: [
      "occi.network.vlan": [
        type: Types.Integer,
        description: "802.1q VLAN Identifier"
      ],
      "occi.network.label": [
        type: Types.String,
        description: "Tag based VLANs"
      ],
      "occi.network.state": [
        type: [:active, :inactive, :error],
        required: true,
        default: :inactive,
        mutable: false,
        description: "Current state of the instance"
      ],
      "occi.network.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ] do
    # action up,
    #   title: "Bring the instance up"
    # action down,
    #   title: "Bring the instance down"
  end

  kind "http://schemas.ogf.org/occi/infrastructure#networkinterface",
    parent: Core.Link,
    attributes: [
      "occi.networkinterface.interface": [
        type: Types.String,
        required: true,
        mutable: false,
        description: "Identifier that relates the link to the link's device interface"
      ],
      "occi.networkinterface.mac": [
        type: {Types.String, [match: "([a-f0-9]{2}:){5}([a-f0-9]{2})"]},
        required: true,
        description: "MAC address associated with the link's device interface"
      ],
      "occi.networkinterface.state": [
        type: [:active, :inactive, :error],
        required: true,
        mutable: false,
        description: "Current status of the interface"
      ],
      "occi.networkinterface.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ]

  mixin "http://schemas.ogf.org/occi/infrastructure/network#ipnetwork",
    applies: [ "http://schemas.ogf.org/occi/infrastructure#network" ],
    attributes: [
      "occi.network.address": [
        type: Types.CIDR,
        required: false,
        description: "IP Network address"
      ],
      "occi.network.gateway": [
        type: Types.CIDR,
        required: false,
        description: "IP Network address"
      ],
      "occi.network.allocation": [
        type: [:dynamic, :static],
        required: false,
        description: "IP allocation type"
      ]
    ]

  mixin "http://schemas.ogf.org/occi/infrastructure/networkinterface#ipnetworkinterface",
    applies: [ "http://schemas.ogf.org/occi/infrastructure#networkinterface" ],
    attributes: [
      "occi.networkinterface.address": [
        type: Types.CIDR,
        required: true,
        description: "IP network address of the link"
      ],
      "occi.networkinterface.gateway": [
        type: Types.CIDR,
        required: false,
        description: "Default gateway of the link"
      ],
      "occi.networkinterface.allocation": [
        type: [:dynamic, :static],
        required: true,
        description: "Address mechanism"
      ]
    ]

  mixin "http://schemas.ogf.org/occi/infrastructure#os_tpl"

  mixin "http://schemas.ogf.org/occi/infrastructure#resource_tpl"

  mixin "http://schemas.ogf.org/occi/infrastructure/credentials#ssh_key",
    applies: [ "http://schemas.ogf.org/occi/infrastructure#compute" ],
    attributes: [
      "occi.credentials.ssh.publickey": [
        type: Types.String,
        required: true,
        description: "The content of the public key file to be injected into the compute resource"
      ]
    ]

  mixin "http://schemas.ogf.org/occi/infrastructure/compute#user_data",
    applies: [ "http://schemas.ogf.org/occi/infrastructure#compute" ],
    attributes: [
      "occi.compute.userdata": [
        type: Types.String,
        required: true,
        mutable: false,
        description: "Contextualization data (e.g.: script, executable) that the client supplies once
        and only once. It cannot be updated."
      ]
    ]
end
