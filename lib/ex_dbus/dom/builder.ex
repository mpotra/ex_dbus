defmodule ExDBus.Builder do
  use ExDBus.Spec, prefix: false

  @spec service(name()) :: {:ok, service()} | {:error, binary()}
  def service(name) do
    {:ok, {:service, name, []}}
  end

  @spec service!(name()) :: service()
  def service!(name) do
    with {:ok, service} <- service(name) do
      service
    else
      {:error, reason} -> raise reason
    end
  end

  @spec root(name()) :: {:ok, object()} | {:error, binary()}
  def root(name \\ "/") do
    object(name)
  end

  @spec root!(name()) :: object()
  def root!(name \\ "/") do
    with {:ok, object} <- root(name) do
      object
    else
      {:error, reason} -> raise reason
    end
  end

  @spec object(name) :: {:ok, object()} | {:error, binary()}
  def object(name) when is_binary(name) do
    {:ok, {:object, name, []}}
  end

  @spec object!(name) :: object()
  def object!(name) do
    with {:ok, object} <- object(name) do
      object
    else
      {:error, reason} -> raise reason
    end
  end

  @spec interface(name) :: {:ok, interface()} | {:error, binary()}
  def interface(name) when is_binary(name) do
    {:ok, {:interface, name, []}}
  end

  @spec interface!(name) :: interface()
  def interface!(name) do
    with {:ok, interface} <- interface(name) do
      interface
    else
      {:error, reason} -> raise reason
    end
  end

  @spec annotation(name, binary() | number() | boolean()) ::
          {:ok, annotation()} | {:error, binary()}
  def annotation(name, value \\ true)

  def annotation(name, value) when is_binary(value) do
    {:ok, {:annotation, name, value}}
  end

  def annotation(name, value) when is_boolean(value) or is_number(value) do
    annotation(name, to_string(value))
  end

  @spec annotation!(name(), binary() | number() | boolean()) :: annotation()
  def annotation!(name, value \\ true) do
    with {:ok, annotation} <- annotation(name, value) do
      annotation
    else
      {:error, reason} -> raise reason
    end
  end

  @spec signal(name) :: {:ok, signal()} | {:error, binary()}
  def signal(name) when is_binary(name) do
    {:ok, {:signal, name, []}}
  end

  @spec signal!(name) :: signal()
  def signal!(name) do
    with {:ok, signal} <- signal(name) do
      signal
    else
      {:error, reason} -> raise reason
    end
  end

  @spec method(name()) :: {:ok, method()} | {:error, binary()}
  def method(name) do
    {:ok, {:method, name, [], nil}}
  end

  @spec method!(name()) :: method()
  def method!(name) do
    with {:ok, method} <- method(name) do
      method
    else
      {:error, reason} -> raise reason
    end
  end

  @spec property(name(), dbus_type(), access()) :: {:ok, property()} | {:error, binary()}
  def property(name, type, access) do
    {:ok, {:property, name, type, access, [], {nil, nil}}}
  end

  @spec property!(name(), dbus_type(), access()) :: property()
  def property!(name, type, access) do
    with {:ok, property} <- property(name, type, access) do
      property
    else
      {:error, reason} -> raise reason
    end
  end

  @spec argument(name(), dbus_type(), direction()) :: {:ok, argument()} | {:error, binary()}
  def argument(name, type, direction \\ :out) do
    {:ok, {:argument, name, type, direction, []}}
  end

  @spec argument!(name(), dbus_type(), direction()) :: annotation()
  def argument!(name, type, direction \\ :out) do
    with {:ok, argument} <- argument(name, type, direction) do
      argument
    else
      {:error, reason} -> raise reason
    end
  end

  @spec set_method_callback!(method(), method_handle()) :: method()
  def set_method_callback!({:method, name, children, _}, callback) when is_function(callback) do
    {:method, name, children, callback}
  end

  @spec set_property_getter!(property(), property_getter()) :: property()
  def set_property_getter!({:property, name, type, access, annotations, {_, setter}}, getter)
      when is_function(getter) do
    {:property, name, type, access, annotations, {getter, setter}}
  end

  @spec set_property_setter!(property(), property_setter()) :: property()
  def set_property_setter!({:property, name, type, access, annotations, {getter, _}}, setter)
      when is_function(setter) do
    {:property, name, type, access, annotations, {getter, setter}}
  end

  @spec get_tag(definition() | service() | any()) :: tag() | nil
  def get_tag({:object, _, _}), do: :object
  def get_tag({:interface, _, _}), do: :interface
  def get_tag({:method, _, _, _}), do: :method
  def get_tag({:signal, _, _}), do: :signal
  def get_tag({:property, _, _, _, _, _}), do: :property
  def get_tag({:annotation, _, _}), do: :annotation
  def get_tag({:argument, _, _, _, _}), do: :argument
  def get_tag({:service, _, _}), do: :service
  def get_tag(_), do: nil
end
