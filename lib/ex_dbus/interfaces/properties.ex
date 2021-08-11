defmodule ExDBus.Interfaces.Properties do
  use ExDBus.Schema
  alias ExDBus.Tree

  node do
    interface "org.freedesktop.DBus.Properties" do
      method "Get" do
        arg("interface_name", "s", :in)
        arg("property_name", "s", :in)
        arg("value", "v", :out)
        callback(&__MODULE__.get/2)
      end

      method "GetAll" do
        arg("interface_name", "s", :in)
        arg("properties", "a{sv}", :out)
        callback(&__MODULE__.get_all/2)
      end

      method "Set" do
        arg("interface_name", "s", :in)
        arg("property_name", "s", :in)
        arg("value", "v", :in)
        callback(&__MODULE__.set/2)
      end

      signal "PropertiesChanged" do
        arg("interface_name", "s")
        arg("changed_properties", "a{sv}")
        arg("invalidated_properties", "as")
      end
    end
  end

  def get({interface_name, property_name}, %{node: object} = state) do
    with {:ok, interface} <- find_interface(object, interface_name),
         {:ok, property} <- find_property(interface, property_name),
         {:ok, getter} <- can_read(property) do
      call_getter(getter, property_name, property)
    end
  end

  def get_all(interface_name, %{node: object} = state) do
    with {:ok, interface} <- find_interface(object, interface_name) do
      values =
        interface
        |> Tree.get_properties()
        |> Enum.map(fn property ->
          name = Tree.property_name(property)

          case can_read(property) do
            {:ok, getter} -> {true, name, getter, property}
            _ -> {false, name, nil}
          end
        end)
        |> Enum.filter(&elem(&1, 0))
        |> Enum.reduce([], fn {_, name, getter, property}, values ->
          case call_getter(getter, name, property) do
            {:ok, [reply_type], [value]} ->
              value = {:dbus_variant, reply_type, value}
              [{name, value} | values]

            _ ->
              values
          end
        end)

      {:ok, [{:dict, :string, :variant}], [values]}
    end
  end

  def set({interface_name, property_name, value}, %{node: object} = state) do
    with {:ok, interface} <- find_interface(object, interface_name),
         {:ok, property} <- find_property(interface, property_name),
         {:ok, setter} <- can_write(property) do
      state = Map.merge(state, %{property: property, interface: interface})

      call_setter(setter, property_name, value, property)
    end
  end

  defp find_interface(object, interface) do
    case Tree.find_interface(object, interface) do
      :error ->
        {:error, "org.freedesktop.DBus.Error.UnknownInterface",
         "Interface #{interface} not found at given path"}

      success ->
        success
    end
  end

  defp find_property({:interface, interface_name, _} = interface, property_name) do
    case Tree.find_property(interface, property_name) do
      :error ->
        {:error, "org.freedesktop.DBus.Error.UnknownProperty",
         "Property #{property_name} not found in interface #{interface_name} at given path"}

      success ->
        success
    end
  end

  defp can_read(property) do
    case Tree.property_access(property) do
      access when access in [:read, :readwrite] ->
        getter = Tree.property_getter(property)

        case getter do
          getter when is_function(getter) ->
            {:ok, getter}

          {:call, _pid, _method_name} = getter ->
            {:ok, getter}

          _ ->
            {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to read property"}
        end

      _ ->
        {:error, "org.freedesktop.DBus.Error.AccessDenied", "The property is not readable"}
    end
  end

  defp call_setter({:call, pid, method_name}, property_name, value, property) do
    setter = fn property_name, value ->
      GenServer.call(pid, {method_name, property_name, value})
    end

    call_setter(setter, property_name, value, property)
  end

  defp call_setter(setter, property_name, value, property) do
    reply_type = unmarshal_type(Tree.property_type(property))

    try do
      setter.(property_name, value)
    rescue
      e ->
        {:error, "org.freedesktop.DBus.Error.Failed", Exception.message(e)}
    else
      :ok ->
        {:ok, reply_type, [value]}

      {:ok, value} ->
        {:ok, reply_type, [value]}

      {:error, type, message} ->
        {:error, type, message}

      {:error, message} ->
        {:error, "org.freedesktop.DBus.Error.Failed", message}

      value ->
        {:ok, reply_type, [value]}
    end
  end

  defp call_getter({:call, pid, method_name}, property_name, property) do
    getter = fn property_name ->
      GenServer.call(pid, {method_name, property_name})
    end

    call_getter(getter, property_name, property)
  end

  defp call_getter(getter, property_name, property) do
    reply_type = unmarshal_type(Tree.property_type(property))

    try do
      getter.(property_name)
    rescue
      e ->
        {:error, "org.freedesktop.DBus.Error.Failed", Exception.message(e)}
    else
      {:ok, value} ->
        {:ok, reply_type, [value]}

      {:error, type, message} ->
        {:error, type, message}

      {:error, message} ->
        {:error, "org.freedesktop.DBus.Error.Failed", message}

      value ->
        {:ok, reply_type, [value]}
    end
  end

  defp can_write(property) do
    case Tree.property_access(property) do
      access when access in [:write, :readwrite] ->
        setter = Tree.property_setter(property)

        case setter do
          setter when is_function(setter) ->
            {:ok, setter}

          {:call, pid, method_name} = setter ->
            {:ok, setter}

          _ ->
            {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to set property"}
        end

      _ ->
        {:error, "org.freedesktop.DBus.Error.PropertyReadOnly", "The property is read-only"}
    end
  end

  defp unmarshal_type(type) do
    {:ok, utype} = :dbus_marshaller.unmarshal_signature(type)
    utype
  end
end
