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

  def get_all(interface_name, %{node: object} = context) do
    with {:ok, interface} <- find_interface(object, interface_name) do
      context = Map.merge(context, %{interface: interface})

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
          case call_getter(getter, interface_name, name, property, context) do
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

  def get({interface_name, property_name}, %{node: object} = context) do
    with {:ok, interface} <- find_interface(object, interface_name),
         {:ok, property} <- find_property(interface, property_name),
         {:ok, getter} <- can_read(property) do
      context = Map.merge(context, %{property: property, interface: interface})
      call_getter(getter, interface_name, property_name, property, context)
    end
  end

  def set({interface_name, property_name, value}, %{node: object} = context) do
    with {:ok, interface} <- find_interface(object, interface_name),
         {:ok, property} <- find_property(interface, property_name),
         {:ok, setter} <- can_write(property) do
      context = Map.merge(context, %{property: property, interface: interface})
      call_setter(setter, interface_name, property_name, value, property, context)
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

  defp call_getter({:call, pid, method_name}, interface_name, property_name, property, context) do
    getter = fn property_name ->
      GenServer.call(pid, {method_name, property_name})
    end

    call_getter(getter, interface_name, property_name, property, context)
  end

  defp call_getter(getter, _interface_name, property_name, property, _context)
       when is_function(getter) do
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

  defp call_getter(
         nil,
         interface_name,
         property_name,
         _property,
         %{
           path: path,
           router: router
         } = context
       )
       when not is_nil(router) do
    try do
      router.get_property(path, interface_name, property_name, context)
    rescue
      _error ->
        {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to read property"}
    else
      :skip ->
        {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to read property"}

      result ->
        result
    end
  end

  defp call_getter(_, _, _, _, _) do
    {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to read property"}
  end

  defp call_setter(
         {:call, pid, method_name},
         interface_name,
         property_name,
         value,
         property,
         context
       ) do
    setter = fn property_name, value ->
      GenServer.call(pid, {method_name, property_name, value})
    end

    call_setter(setter, interface_name, property_name, value, property, context)
  end

  defp call_setter(setter, _interface_name, property_name, value, property, _context)
       when is_function(setter) do
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

  defp call_setter(
         nil,
         interface_name,
         property_name,
         value,
         _property,
         %{
           path: path,
           router: router
         } = context
       )
       when not is_nil(router) do
    try do
      router.set_property(path, interface_name, property_name, value, context)
    rescue
      _error ->
        {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to write property"}
    else
      :skip ->
        {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to write property"}

      result ->
        result
    end
  end

  defp call_setter(_, _, _, _, _, _) do
    {:error, "org.freedesktop.DBus.Error.NotSupported", "Failed to set property"}
  end

  defp can_read(property) do
    case Tree.property_access(property) do
      access when access in [:read, :readwrite] ->
        {:ok, Tree.property_getter(property)}

      _ ->
        {:error, "org.freedesktop.DBus.Error.AccessDenied", "The property is not readable"}
    end
  end

  defp can_write(property) do
    case Tree.property_access(property) do
      access when access in [:write, :readwrite] ->
        {:ok, Tree.property_setter(property)}

      _ ->
        {:error, "org.freedesktop.DBus.Error.PropertyReadOnly", "The property is read-only"}
    end
  end

  defp unmarshal_type(type) do
    {:ok, utype} = :dbus_marshaller.unmarshal_signature(type)
    utype
  end
end
