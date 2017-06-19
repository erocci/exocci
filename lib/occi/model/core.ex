defmodule OCCI.Model.Core do
  defmacro kind_resource do
    :"http://schemas.ogf.org/occi/core#resource" 
  end

  defmacro kind_link do
    :"http://schemas.ogf.org/occi/core#link"
  end
end
