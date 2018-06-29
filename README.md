# Exocci

[![Hex.pm](https://img.shields.io/hexpm/v/occi.svg)](https://hex.pm/packages/occi)

[![Build Status](https://travis-ci.org/erocci/exocci.svg?branch=master)](https://travis-ci.org/erocci/exocci)

`exocci` implements
the [OCCI meta-model](http://occi-wg.org/about/specification/)
([Core](http://ogf.org/documents/GFD.221.pdf),
[Infrastructure](http://ogf.org/documents/GFD.224.pdf)) with a specific DSL.

`OCCI.Model.Infrastructure` module is an example of model defined with the DSL.

See the [generated documentation](http://hexdocs.pm/exocci) for more
detailed explanations.

## Installation

    Add `exocci` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:exocci, "~> 0.1.0"}]
    end
    ```

## TODO

* Use protocol for serialization
