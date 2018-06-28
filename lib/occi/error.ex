defmodule OCCI.Error do
  defexception [:message, :log, :code]

  def exception({_backend, _state, code}) when code < 500 do
    exc(code, to_msg(code))
  end

  def exception({backend, state, code}) when is_integer(code) do
    msg = to_msg(code)

    log = """
    OCCI backend #{inspect(backend)}: #{msg}

    State:
    #{inspect(state)}
    """

    exc(code, msg, log)
  end

  def exception({backend, state, reason}) do
    log = """
    OCCI backend #{inspect(backend)}: #{reason}

    State:
    #{inspect(state)}
    """

    exc(500, reason, log)
  end

  def exception({code, msg}) when is_integer(code) do
    exc(code, msg)
  end

  def exception(code) when is_integer(code) do
    exc(code, to_msg(code))
  end

  def exception(reason) do
    exc(500, "#{inspect(reason)}")
  end

  ###
  ### Priv
  ###
  def exc(code, msg, log \\ nil)

  def exc(code, msg, log) when code < 500 do
    %OCCI.Error{message: msg, code: code, log: log}
  end

  def exc(code, msg, log) do
    log =
      if log do
        log
      else
        "OCCI Error (#{code}): #{msg}"
      end

    %OCCI.Error{message: to_msg(code), code: code, log: log}
  end

  defp to_msg(404), do: "Entity not found"
  defp to_msg(409), do: "Conflict"
  defp to_msg(422), do: "Unprocessable entity"
  defp to_msg(_), do: "Internal error"
end
