defmodule OCCI.Mixin do
  @moduledoc """
  This module should not be used directly but through the macro
  `OCCI.Model.mixin/2`
  """
  alias OCCI.Category.Helpers

  @doc false
  defmacro __using__(opts) do
    tag = Keyword.get(opts, :tag, false)

    depends = opts |> Keyword.get(:depends, []) |> Enum.map(&Macro.expand(&1, __CALLER__))
    applies = opts |> Keyword.get(:applies, []) |> Enum.map(&Macro.expand(&1, __CALLER__))

    opts = [{:type, :mixin} | opts]

    quote do
      use OCCI.Category, unquote(opts)

      Module.register_attribute(__MODULE__, :actions, accumulate: true)
      Module.register_attribute(__MODULE__, :action_mods, accumulate: true)

      @before_compile OCCI.Mixin

      @tag unquote(tag)

      @depends unquote(depends)
      @applies unquote(applies)

      def depends, do: @depends
      def applies, do: @applies

      def depends! do
        Enum.reduce(@depends, OCCI.OrdSet.new(), fn dep, acc ->
          if dep in acc do
            acc
          else
            depends = dep.depends!()
            acc ++ [dep | depends]
          end
        end)
      end

      @doc """
      Return true if this mixin applies to the given kind
      """
      def apply?(kind) do
        Enum.any?(@applies, fn
          ^kind ->
            true

          apply ->
            Enum.any?(apply.parent!(), fn
              ^kind -> true
              _ -> false
            end)
        end)
      end

      @doc """
      Return true if mixin is user defined (tag)
      """
      def tag?, do: @tag
    end
  end

  defmacro __before_compile__(_opts) do
    Helpers.__gen_doc__(__CALLER__)
    Helpers.__def_attributes__(__CALLER__)
    Helpers.__def_actions__(__CALLER__)
  end
end
