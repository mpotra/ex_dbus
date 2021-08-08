defmodule ErlangDBus.Message do
  def get_field(:invalid, message) do
    :dbus_message.get_field(0, message)
  end

  def get_field(:path, message) do
    :dbus_message.get_field(1, message)
  end

  def get_field(:interface, message) do
    :dbus_message.get_field(2, message)
  end

  def get_field(:member, message) do
    :dbus_message.get_field(3, message)
  end

  def get_field(:error_name, message) do
    :dbus_message.get_field(4, message)
  end

  def get_field(:reply_serial, message) do
    :dbus_message.get_field(5, message)
  end

  def get_field(:destination, message) do
    :dbus_message.get_field(6, message)
  end

  def get_field(:sender, message) do
    :dbus_message.get_field(7, message)
  end

  def get_field(:signature, message) do
    :dbus_message.get_field(8, message)
  end
end
