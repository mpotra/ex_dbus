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
      e ->
        {:error, "org.freedesktop.DBus.Error.Failed", "#{inspect(e)}"}
    else
      msg -> msg
    end
  end

  @spec error(dbus_message(), String.t(), String.t()) :: dbus_message() | dbus_error()
  def error(msg, name, message) do
    try do
      :dbus_message.error(msg, name, message)
    rescue
      e -> {:error, "org.freedesktop.DBus.Error.Failed", "#{inspect(e)}"}
    else
      msg -> msg
    end
  end

  @spec signal(
          destination :: nil | String.t(),
          path :: String.t(),
          interface :: String.t(),
          signal :: String.t(),
          {signature :: String.t() | nil, types :: list(), args :: list()}
        ) :: {:ok, dbus_message()}
  def signal(_destination, path, interface, signal, {_, [], []}) do
    {body, _pos} = :dbus_marshaller.marshal_list([], [])

    fields = [
      {1, {:dbus_variant, :object_path, path}},
      {2, {:dbus_variant, :string, interface}},
      {3, {:dbus_variant, :string, signal}}
      #  {8,}, # FIELD_SIGNATURE
      #  {6, } # FIELD_DESTINATION
    ]

    header = {:dbus_header, ?l, 4, 0, 1, 0, :undefined, fields}

    {:ok, {:dbus_message, header, body}}
  end

  def signal(_destination, path, interface, signal, {signature, types, args}) do
    {body, _pos} = :dbus_marshaller.marshal_list(types, args)

    fields = [
      {1, {:dbus_variant, :object_path, path}},
      {2, {:dbus_variant, :string, interface}},
      {3, {:dbus_variant, :string, signal}},
      {8, {:dbus_variant, :signature, signature}}
    ]

    header = {:dbus_header, ?l, 4, 0, 1, 0, :undefined, fields}

    {:ok, {:dbus_message, header, body}}
  end

  def set_field({:dbus_message, header, body}, field) do
    header = set_field(header, field)
    {:dbus_message, header, body}
  end

  def set_field({:dbus_header, endian, type, flags, version, size, serial, fields}, field) do
    fields = [field | fields]
    {:dbus_header, endian, type, flags, version, size, serial, fields}
  end

  def set_body(signature, types, body, msg) when is_list(types) do
    :dbus_message.set_body(signature, types, body, msg)
  end

  def set_size({:dbus_header, endian, type, flags, version, _, serial, fields}, size) do
    {:dbus_header, endian, type, flags, version, size, serial, fields}
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
