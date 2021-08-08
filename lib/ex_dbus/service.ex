defmodule ExDBus.Service do
  alias ExDBus.Builder
  alias ExDBus.Tree

  defmacro __using__(opts) do
    service_name = Keyword.get(opts, :service, nil)

    quote do
      use GenServer

      @service_name unquote(service_name)
      @schema __MODULE__

      @before_compile ExDBus.Service

      def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      # def reply({pid, from}, reply) do
      #   GenServer.cast(pid, {:reply, from, reply})
      # end

      # def signal(signal) do
      #   signal(signal, [])
      # end

      # def signal(signal, args) do
      #   signal(signal, args, [])
      # end

      # def signal(signal, args, options) do
      #   IO.inspect("Sending signal #{signal}")
      #   GenServer.cast(__MODULE__, {:signal, signal, args, options})
      # end

      # def test(p) do
      #   GenServer.call(__MODULE__, {:test, p})
      # end

      @impl true
      def init(_stack) do
        IO.inspect(self(), label: "INIT PID")
        service_name = __service__(:name)
        root = __service__(:schema)

        {:ok, {bus, service}} = register_service(self(), service_name)

        state = %{
          name: service_name,
          root: root,
          bus: bus,
          service: service
        }

        {:ok, state}
      end

      @impl true
      def handle_call(request, from, state) do
        IO.inspect(from, label: "[CALL] Message from")
        IO.inspect(request, label: "[CALL] Message request")
        {:noreply, state}
      end

      @impl true
      def handle_cast(request, state) do
        IO.inspect(request, label: "[CAST] Request")
        {:noreply, state}
      end

      @impl true
      def handle_info(message, state) do
        IO.inspect(message, label: "----[INFO]-----")
        state = ExDBus.Service.handle_info(message, state, &dbus_method_call/2)
        {:noreply, state}
      end

      defp register_service(pid, service_name) do
        ExDBus.Service.register_service(pid, service_name)
      end

      defp dbus_method_call(method, state) do
        ExDBus.Service.dbus_method_call(method, state)
      end

      defoverridable register_service: 2,
                     dbus_method_call: 2
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __service__(:name) do
        @service_name
      end

      def __service__(:schema) do
        @schema.__schema__()
      end

      # def __service__(:name) do
      #   @service_name
      # end

      # def __service__(:root) do
      #   unless function_exported?(@schema, :__schema__, 1) == false do
      #     raise RuntimeError, "Schema (#{@schema}) does not expose a DBUS schema"
      #   end

      #   @schema.__schema__(:root)
      # end

      # def __root__() do
      #   __service__(:root)
      # end

      # defp __register_service__(pid, service_name) do
      #   {:ok, service} = :dbus_service_reg.export_service(pid, service_name)
      #   {:ok, service2} = :dbus_service_reg.export_service(service_name)
      #   # :ok = :dbus_service.register_object(service, unquote(root_path), pid)

      #   :ok = :dbus_service.register_object(service2, "/StatusNotifierItem", pid)

      #   # The exported service is not visible, because no connections
      #   # are started until the first call to :dbus_bus_reg.get_bus(:session)
      #   # Call it every time a new service is registered.
      #   {:ok, bus} = :dbus_bus_reg.get_bus(:session)
      #   {:ok, {bus, service}}
      # end

      # defp __register_service__2(pid) do
      #   # {:ok, service} = :dbus_service_reg.export_service(unquote(service_name))
      #   # :ok = :dbus_service.register_object(service, unquote(root_path), self())

      #   # The exported service is not visible, because no connections
      #   # are started until the first call to :dbus_bus_reg.get_bus(:session)
      #   # Call it every time a new service is registered.
      #   {:ok, bus} = :dbus_bus_reg.get_bus(:session)

      #   {:ok, service} = :dbus_service.start_link(unquote(service_name))

      #   :ok = :dbus_bus.export_service(bus, unquote(service_name))

      #   :ok = :dbus_service.register_object(service, unquote(root_path), pid)
      #   [service: nil]
      # end
    end
  end

  def register_service(pid, service_name) do
    {:ok, service} = :dbus_service_reg.export_service(pid, service_name)
    {:ok, service2} = :dbus_service_reg.export_service(service_name)
    # :ok = :dbus_service.register_object(service, unquote(root_path), pid)

    :ok = :dbus_service.register_object(service2, "/StatusNotifierItem", pid)

    # The exported service is not visible, because no connections
    # are started until the first call to :dbus_bus_reg.get_bus(:session)
    # Call it every time a new service is registered.
    {:ok, bus} = :dbus_bus_reg.get_bus(:session)
    {:ok, {bus, service}}
  end

  # def dbus_method_call({"/", "org.freedesktop.DBus.Introspectable", "Introspect", _}, %{
  #       root: root
  #     }) do
  #   xml_body = ExDBus.XML.to_xml(root)
  #   {:ok, [:string], [xml_body]}
  # end

  # def dbus_method_call({path, "org.freedesktop.DBus.Properties", "GetAll", interface_name}, %{
  #       root: root
  #     }) do
  #   IO.inspect({path, interface_name}, label: "DBUS_METHOD_CALL:")

  #   with {:ok, object} <- Builder.Finder.find(root, path),
  #        {:ok, interface} <- Builder.Finder.find(object, interface_name) do
  #     IO.inspect({:reply, path, interface_name}, label: "DBUS_METHOD_CALL REPLY:")

  #     type = {:dict, :string, :variant}

  #     values = %{"Prop" => "MyPropValue"}

  #     {:ok, [type], [values]}
  #   else
  #     _ ->
  #       {:error, "org.freedesktop.DBus.Error.UnknownMethod",
  #        "ExDBus: Interface not found: #{path}/#{interface_name}"}
  #   end
  # end

  def dbus_method_call({path, interface, method, args} = m, %{root: root}) do
    IO.inspect(m, label: "[DBUS_METHOD_CALL]")
    IO.inspect(Tree.find_path([root], path), label: "Find object")

    with {:object, {:ok, object}} <- {:object, Tree.find_path([root], path)},
         {:interface, {:ok, interface}} <- {:interface, Tree.find_interface(object, interface)},
         {:method, {:ok, method}} <- {:method, Tree.find_method(interface, method, args)} do
      {:error, "SKIP", "SKIP"}
    else
      {:object, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownObject", "No such object in the service"}

      {:interface, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownObject", "Interface not found at given path"}

      {:method, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownMethod",
         "Method not found on given interface"}
    end
    |> IO.inspect(label: "[DBUS_METHOD_CALL] Result")
  end

  # def dbus_method_call({path, iface, method, args} = m, %{root: root}) do
  #   IO.inspect(m, label: "[DBUS_METHOD_CALL]")
  #   {:error, "org.freedesktop.DBus.Error.UnknownMethod", "ExDBus: Function not found: #{method}"}
  # end

  def handle_info({:dbus_method_call, msg, conn}, state, fn_dbus_method_call)
      when is_function(fn_dbus_method_call) do
    path = ErlangDBus.Message.get_field(:path, msg)
    interface = ErlangDBus.Message.get_field(:interface, msg)
    member = ErlangDBus.Message.get_field(:member, msg)

    body =
      case msg do
        {:dbus_message, _, :undefined} -> nil
        {:dbus_message, _, body} -> body
      end

    method = {path, interface, member, body}

    reply =
      case fn_dbus_method_call.(method, state) do
        {:ok, types, values} ->
          :dbus_message.return(msg, types, values)

        {:error, name, message} ->
          :dbus_message.error(msg, name, message)
      end

    :ok = :dbus_connection.cast(conn, reply)

    state
  end
end
