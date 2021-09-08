defmodule ErlangDBus.Message do
  @type dbus_variant() ::
          {:dbus_variant, atom | {:array, any} | {:struct, list} | {:dict, any, any}, any}
  @type dbus_header() ::
          {:dbus_header, integer, integer, integer, integer, integer, :undefined | integer, list}
  @type dbus_message() :: {:dbus_message, dbus_header(), any}
  @type dbus_error() :: ExDBus.Spec.dbus_reply_error()
  @type field() ::
          :destination
          | :error_name
          | :interface
          | :invalid
          | :member
          | :path
          | :reply_serial
          | :sender
          | :signature
  @spec get_field(field(), dbus_message() | dbus_header()) :: String.t()
  def get_field(field, {:dbus_message, header, _}) do
    get_field(field, header)
  end

  def get_field(:invalid, message) do
    _get_field(0, message)
  end

  def get_field(:path, message) do
    _get_field(1, message)
  end

  def get_field(:interface, message) do
    _get_field(2, message)
  end

  def get_field(:member, message) do
    _get_field(3, message)
  end

  def get_field(:error_name, message) do
    _get_field(4, message)
  end

  def get_field(:reply_serial, message) do
    _get_field(5, message)
  end

  def get_field(:destination, message) do
    _get_field(6, message)
  end

  def get_field(:sender, message) do
    _get_field(7, message)
  end

  def get_field(:signature, message) do
    _get_field(8, message)
  end

  # Find field
  @spec find_field(field(), dbus_message() | dbus_header()) :: :undefined | String.t()
  def find_field(:invalid, message) do
    _find_field(0, message)
  end

  def find_field(:path, message) do
    _find_field(1, message)
  end

  def find_field(:interface, message) do
    _find_field(2, message)
  end

  def find_field(:member, message) do
    _find_field(3, message)
  end

  def find_field(:error_name, message) do
    _find_field(4, message)
  end

  def find_field(:reply_serial, message) do
    _find_field(5, message)
  end

  def find_field(:destination, message) do
    _find_field(6, message)
  end

  def find_field(:sender, message) do
    _find_field(7, message)
  end

  def find_field(:signature, message) do
    _find_field(8, message)
  end

  @spec return(dbus_message(), list(), list()) :: dbus_message() | dbus_error()
  def return(msg, types, values) do
    try do
      :dbus_message.return(msg, types, values)
    rescue
      e -> {:error, "org.freedesktop.DBus.Error.Failed", e.message}
    else
      msg -> msg
    end
  end

  @spec return(dbus_message(), String.t(), String.t()) :: dbus_message() | dbus_error()
  def error(msg, name, message) do
    try do
      :dbus_message.error(msg, name, message)
    rescue
      e -> {:error, "org.freedesktop.DBus.Error.Failed", e.message}
    else
      msg -> msg
    end
  end

  defp _get_field(pos, message) do
    try do
      case :dbus_message.get_field(pos, message) do
        {:dbus_variant, _, _} -> ""
        str -> str
      end
    rescue
      _e -> ""
    else
      return -> return
    end
  end

  defp _find_field(pos, message) do
    try do
      case :dbus_message.find_field(pos, message) do
        {:dbus_variant, _, _} -> :undefined
        str -> str
      end
    rescue
      _e -> :undefined
    else
      return -> return
    end
  end
end
