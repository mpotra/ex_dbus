defmodule ExDBus.Service do
  require Logger
  use GenServer
  alias ExDBus.Tree
  alias ExDBus.Spec
  alias ErlangDBus.Message

  def start_link(opts, gen_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      gen_opts
    )
  end

  @impl true
  def init([_ | _] = opts) do
    service_name = Keyword.get(opts, :name, nil)
    schema = Keyword.get(opts, :schema, nil)
    server = Keyword.get(opts, :server, nil)
    router = Keyword.get(opts, :router, nil)
    # Default cookie for EXTERNAL auth mechanism, for user uid 1000
    cookie = Keyword.get(opts, :cookie, "31303030")

    # if service_name == nil do
    #   # raise "Service requires the :name option"
    # end

    if schema == nil do
      raise "Service requires the :schema option"
    end

    root = get_root(schema)

    state = %{
      name: service_name,
      root: root,
      bus: nil,
      service: nil,
      server: server,
      registered_objects: %{},
      router: router,
      cookie: cookie,
      error: nil
    }

    if cookie == :system_user do
      case fetch_system_uid() do
        {:ok, ""} -> Logger.warn("Failed to set D-Bus cookie :user : Empty uid")
        {:ok, uid} -> set_dbus_cookie(Base.encode16(uid))
        {:error, error} -> Logger.warn("Failed to set D-Bus cookie :user : #{inspect(error)}")
      end
    else
      # erlang-dbus hardcodes the "1000" uid cookie as default.
      if is_binary(cookie) and String.length(cookie) > 0 and cookie != "31303030" do
        set_dbus_cookie(cookie)
      end
    end

    case connect_bus(self()) do
      {:ok, bus} ->
        state = Map.put(state, :bus, bus)

        if service_name != nil do
          case register_name(bus, service_name) do
            :ok ->
              {:ok, state}

            error ->
              ExDBus.Bus.close(bus)
              {:stop, error}
          end
        else
          {:ok, state}
        end

        {:ok, state}

      error ->
        Logger.debug("Failed to connect to D-Bus: #{inspect(error)}")
        {:ok, Map.put(state, :error, error)}
    end
  end

  def get_root(schema) when is_atom(schema) do
    schema.__schema__()
  end

  def get_root({:object, _, _} = root) do
    root
  end

  def get_root(_) do
    raise "Invalid :schema provided. Must be a module or a :object tree struct"
  end

  def get_bus(service_pid) do
    GenServer.call(service_pid, :get_bus)
  end

  @spec get_name(pid() | {:via, atom(), any()}) :: nil | String.t()
  def get_name(service_pid) do
    GenServer.call(service_pid, :get_name)
  end

  @spec get_dbus_pid(pid()) :: {:ok, String.t()} | {:error, any()}
  def get_dbus_pid(service_pid) do
    GenServer.call(service_pid, :get_dbus_pid)
  end

  def get_router(service_pid) do
    GenServer.call(service_pid, :get_router)
  end

  def set_router(service_pid, router) do
    GenServer.call(service_pid, {:set_router, router})
  end

  def register_object(service_pid, path) do
    GenServer.call(service_pid, {:register_object, path, service_pid})
  end

  def register_object(service_pid, path, server_pid)
      when is_pid(server_pid) or is_atom(server_pid) do
    GenServer.call(service_pid, {:register_object, path, server_pid})
  end

  def unregister_object(service_pid, path) do
    GenServer.call(service_pid, {:unregister_object, path})
  end

  def is_object_registered?(service_pid, path) do
    GenServer.call(service_pid, {:is_object_registered, path})
  end

  def call_method(pid, bus, path, interface, method, args) do
    GenServer.call(pid, {:call_method, bus, path, interface, method, args})
  end

  def send_signal(pid, path, interface, signal) do
    GenServer.cast(pid, {:send_signal, path, interface, signal})
  end

  def send_signal(pid, path, interface, signal, {signature, types, args}) do
    GenServer.cast(pid, {:send_signal, path, interface, signal, {signature, types, args}})
  end

  defp __register_object(%{registered_objects: objects} = state, path, pid) do
    # Do register
    objects = Map.put(objects, path, pid)
    Map.put(state, :registered_objects, objects)
  end

  defp __unregister_object(%{registered_objects: objects} = state, path) do
    # Do unregister
    objects = Map.delete(objects, path)
    Map.put(state, :registered_objects, objects)
  end

  defp __get_registered_object(%{registered_objects: objects}, path) do
    case Map.get(objects, path, nil) do
      nil ->
        {:error, "Object not registered"}

      pid ->
        if Process.alive?(pid) do
          {:ok, pid}
        else
          {:error, "Object service not alive"}
        end
    end
  end

  # handle_call

  @impl true
  def handle_call(:get_name, _from, %{name: name} = state) do
    {:reply, name, state}
  end

  def handle_call(:get_bus, _from, %{bus: bus} = state) do
    {:reply, bus, state}
  end

  def handle_call(:get_dbus_pid, _from, %{bus: bus} = state) when is_pid(bus) do
    reply = ExDBus.Bus.get_dbus_pid(bus)
    {:reply, reply, state}
  end

  def handle_call(:get_dbus_pid, _from, state) do
    {:reply, {:error, "No DBUS bus service running"}, state}
  end

  def handle_call(:get_router, _from, %{router: router} = state) do
    {:reply, {:ok, router}, state}
  end

  def handle_call({:set_router, router}, _from, state) do
    {:reply, {:ok, router}, Map.put(state, :router, router)}
  end

  def handle_call({:get_object, path}, _from, %{root: root} = state) do
    {:reply, Tree.find_path(root, path), state}
  end

  def handle_call({:get_interface, path, name}, _from, %{root: root} = state) do
    with {:ok, object} <- Tree.find_path(root, path) do
      {:reply, Tree.find_interface(object, name), state}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call({:introspect, destination, path}, _from, %{bus: bus} = state) do
    reply = GenServer.call(bus, {:introspect, destination, path})
    {:reply, reply, state}
  end

  def handle_call({:find_object, destination, path}, _from, %{bus: bus} = state) do
    reply = GenServer.call(bus, {:find_object, destination, path})
    {:reply, reply, state}
  end

  def handle_call({:has_object, destination, path}, _from, %{bus: bus} = state) do
    reply = GenServer.call(bus, {:has_object, destination, path})
    {:reply, reply, state}
  end

  def handle_call({:has_interface, destination, path, interface}, _from, %{bus: bus} = state) do
    reply = GenServer.call(bus, {:has_interface, destination, path, interface})
    {:reply, reply, state}
  end

  def handle_call(
        {:call_method, destination, path, interface, method, {signature, types, body}},
        _from,
        %{bus: bus} = state
      ) do
    reply =
      GenServer.call(bus, {
        :call_method,
        destination,
        path,
        interface,
        method,
        {signature, types, body}
      })

    {:reply, reply, state}
  end

  def handle_call(
        {:register_object, path, server_pid},
        _from,
        state
      ) do
    case handle_call({:is_object_registered, path}, nil, state) do
      {:reply, false, state} ->
        {:reply, {:ok, server_pid}, __register_object(state, path, server_pid)}

      {:reply, true, state} ->
        {:reply, {:error, "Object path already registered to a server"}, state}
    end
  end

  def handle_call(
        {:unregister_object, path},
        _from,
        %{registered_objects: objects} = state
      ) do
    case handle_call({:is_object_registered, path}, nil, state) do
      {:reply, true, state} ->
        {:reply, {:ok, Map.get(objects, path)}, __unregister_object(state, path)}

      {:reply, false, state} ->
        {:reply, {:error, "Object path not registered"}, state}
    end
  end

  def handle_call({:is_object_registered, path}, _, %{registered_objects: objects} = state) do
    case Map.get(objects, path, nil) do
      nil ->
        {:reply, false, state}

      pid ->
        if Process.alive?(pid) do
          {:reply, true, state}
        else
          {:reply, false, __unregister_object(state, path)}
        end
    end
  end

  def handle_call({:replace_interface, path, interface}, _from, %{root: root} = state) do
    case Tree.replace_interface_at(root, path, interface) do
      {:ok, root} -> {:reply, :ok, Map.put(state, :root, root)}
      _ -> {:reply, :error, state}
    end
  end

  def handle_call(request, from, state) do
    IO.inspect(from, label: "[CALL] Message from")
    IO.inspect(request, label: "[CALL] Message request")
    {:noreply, state}
  end

  # handle_cast

  @impl true
  def handle_cast(
        {:send_signal, path, interface, signal},
        %{bus: bus} = state
      ) do
    GenServer.cast(bus, {
      :send_signal,
      path,
      interface,
      signal
    })

    {:noreply, state}
  end

  def handle_cast(
        {:send_signal, path, interface, signal, {signature, types, args}},
        %{bus: bus} = state
      ) do
    GenServer.cast(bus, {
      :send_signal,
      path,
      interface,
      signal,
      {signature, types, args}
    })

    {:noreply, state}
  end

  def handle_cast(request, state) do
    IO.inspect(request, label: "[CAST] Request")
    {:noreply, state}
  end

  # handle_info

  @impl true
  def handle_info({:dbus_method_call, msg, conn} = instr, state) do
    path = Message.get_field(:path, msg)

    case __get_registered_object(state, path) do
      {:ok, handle} ->
        Process.send_after(handle, instr, 1, [])

      _ ->
        state = handle_dbus_method_call(msg, conn, state)
        {:noreply, state}
    end
  end

  def handle_info(message, state) do
    IO.inspect(message, label: "----[INFO]-----")
    {:noreply, state}
  end

  def handle_dbus_method_call(msg, conn, state) do
    path = Message.get_field(:path, msg)
    interface = Message.get_field(:interface, msg)
    member = Message.get_field(:member, msg)

    signature =
      Message.find_field(:signature, msg)
      |> case do
        :undefined -> ""
        s -> s
      end

    body =
      case msg do
        {:dbus_message, _, :undefined} -> nil
        {:dbus_message, _, body} -> body
      end

    method = {path, interface, member, signature, body}

    reply =
      case exec_dbus_method_call(method, state) do
        {:ok, types, values} ->
          Message.return(msg, types, values)

        {:error, name, message} ->
          Message.error(msg, name, message)
      end

    case reply do
      {:error, _, _} ->
        :ok

      _ ->
        try do
          :dbus_connection.cast(conn, reply)
        rescue
          _ -> nil
        end
    end

    state
  end

  @spec exec_dbus_method_call(
          {path :: String.t(), interface_name :: String.t(), method_name :: String.t(),
           signature :: String.t(), body :: any},
          state :: map()
        ) ::
          Spec.dbus_reply()
  def exec_dbus_method_call({path, interface_name, method_name, signature, args}, %{
        root: root,
        router: router
      }) do
    with {:object, {:ok, object}} <- {:object, Tree.find_path([root], path)},
         {:interface, {:ok, interface}} <-
           {:interface, Tree.find_interface(object, interface_name)},
         {:method, {:ok, method}} <-
           {:method, Tree.find_method(interface, method_name, signature)} do
      case Tree.get_method_callback(method) do
        {:ok, callback} ->
          call_method_callback(
            callback,
            method_name,
            args,
            %{
              node: object,
              path: path,
              interface: interface_name,
              method: method_name,
              signature: signature,
              router: router
            }
          )

        nil ->
          route_method(router, path, interface_name, method_name, signature, args, %{
            node: object,
            router: router
          })

        _ ->
          {:error, "org.freedesktop.DBus.Error.UnknownMethod",
           "Method not found on given interface"}
      end
    else
      {:object, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownObject",
         "No such object (#{path}) in the service"}

      {:interface, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownInterface",
         "Interface (#{interface_name}) not found at given path"}

      {:method, _} ->
        {:error, "org.freedesktop.DBus.Error.UnknownMethod",
         "Method (#{method_name}) not found on given interface"}
    end
  end

  # @spec register_service(pid(), String.t()) :: {:ok, {pid(), pid()}} | :ignore | {:error, any}
  # def register_service(service_pid, service_name) do
  #   with {:ok, bus} <- ExDBus.Bus.start_link(:session),
  #        :ok <- ExDBus.Bus.connect(bus, service_pid),
  #        :ok <- ExDBus.Bus.register_name(bus, service_name) do
  #     {:ok, {service_pid, bus}}
  #   end
  # end

  defp register_name(bus, service_name) do
    ExDBus.Bus.register_name(bus, service_name)
  end

  defp connect_bus(service_pid) do
    with {:ok, bus} <- ExDBus.Bus.start_link(:session),
         :ok <- ExDBus.Bus.connect(bus, service_pid) do
      {:ok, bus}
    end
  end

  # defp route_method(nil, _path, _interface, _method, _args, _context) do
  #   {:error, "org.freedesktop.DBus.Error.UnknownMethod", "Method not found on given interface"}
  # end

  defp route_method(router, path, interface, method, signature, args, context) do
    try do
      ExDBus.Router.Protocol.method(router, path, interface, method, signature, args, context)
    rescue
      _e ->
        {:error, "org.freedesktop.DBus.Error.UnknownMethod",
         "Method not found on given interface"}
    else
      :skip ->
        {:error, "org.freedesktop.DBus.Error.UnknownMethod",
         "Method not found on given interface"}

      result ->
        result
    end
  end

  defp call_method_callback(callback, _method_name, args, context) when is_function(callback) do
    try do
      callback.(args, context)
    rescue
      e -> {:error, "org.freedesktop.DBus.Error.Failed", e.message}
    else
      return -> return
    end
  end

  defp call_method_callback({:call, pid, remote_method}, method_name, args, context) do
    GenServer.call(pid, {remote_method, method_name, args, context})
  end

  defp fetch_system_uid() do
    case get_env(:uid) do
      {:ok, uid} ->
        {:ok, uid}

      _ ->
        case get_env(:user) do
          {:ok, uid} -> {:ok, uid}
          error -> error
        end
    end
  end

  defp get_env(:uid) do
    case System.get_env("UID") do
      "" -> {:error, "Missing UID env variable"}
      uid when is_binary(uid) -> {:ok, uid}
      _ -> {:error, "Invalid UID env variable"}
    end
  end

  defp get_env(:user) do
    case System.get_env("USER") do
      "" -> {:error, "Missing USER env variable"}
      user when is_binary(user) -> get_user_uid(user)
      _ -> {:error, "Invalid USER env variable"}
    end
  end

  defp get_user_uid(username) when is_binary(username) do
    try do
      case System.cmd("id", ["-u", username]) do
        {uidn, 0} -> {:ok, String.trim(uidn)}
        {_, exit_code} -> {:error, "Failed to get username uid with exit code #{exit_code}"}
      end
    rescue
      error -> {:error, error}
    end
  end

  defp set_dbus_cookie(cookie) when is_binary(cookie) do
    Application.put_env(:dbus, :external_cookie, cookie)
  end
end
