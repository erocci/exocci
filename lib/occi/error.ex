defmodule OCCI.Error do
  defexception [:message, :log, :code]

  def exception({code, msg}) when is_integer(code) do
    exception(code, msg)
  end
  def exception(code) when is_integer(code) do
    exception(code, to_msg(code))
  end
  def exception(reason) do
    exception(500, "#{inspect reason}")
  end

  ###
  ### Priv
  ###
  def exception(code, msg) when code >= 400 and code < 500 do
    %OCCI.Error{ message: msg, code: code, log: nil }
  end
  def exception(code, msg) do
    log = "OCCI Error (#{code}): #{msg}"
    %OCCI.Error{ message: to_msg(code), code: code, log: log }
  end

  defp to_msg(404), do: "Entity not found"
  defp to_msg(409), do: "Conflict"
  defp to_msg(422), do: "Unprocessable entity"
  defp to_msg(_), do: "Internal error"
end
