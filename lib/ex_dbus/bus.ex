defmodule ExDBus.Bus do
  use GenServer
  @type bus_id() :: :session | :system
  @type status() :: :init | :connected | :disconnected

  defmodule State do
    alias ExDBus.DBus.Bus

    defstruct id: :session,
              connection: nil,
              bus: nil,
              service: nil,
              status: :init

    @type t() :: %__MODULE__{
            id: Bus.bus_id(),
            connection: any(),
            bus: pid(),
            service: pid() | nil,
            status: Bus.status()
          }
  end

  @spec start_link(bus_id(), keyword()) :: any()
  def start_link(bus_id, opts \\ []) do
    GenServer.start_link(__MODULE__, bus_id, opts)
  end

  @spec connect(pid(), pid() | nil | String.t()) :: :ok | {:error, binary()}
  def connect(bus_pid \\ __MODULE__, service \\ nil) do
    GenServer.call(bus_pid, {:connect, service})
  end

  @spec(close(pid()) :: :ok, {:error, binary()})
  def close(bus_pid \\ __MODULE__) do
    GenServer.call(bus_pid, :disconnect)
  end

  @spec register_service(pid(), String.t(), pid()) :: :ok | {:error, binary()}
  def register_service(bus_pid, service_name, server_pid) do
    GenServer.call(bus_pid, {:register_service, service_name, server_pid})
  end

  # GenServer implementation

  @impl true
  def init(bus_id) when bus_id in [:session, :system] do
    state = %__MODULE__.State{
      id: bus_id,
      connection: nil,
      bus: self(),
      service: nil,
      status: :init
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:connect, service}, from, %{id: bus_id} = state) do
    if can_connect?(state) do
      case __connect(bus_id, service, state) do
        {:ok, state} ->
          {:reply, :ok, state}

        {:error, error} ->
          {:reply, {:error, error}, state}
      end
    else
      {:reply, {:error, "Unable to connect"}, state}
    end
  end

  def handle_call(:disconnect, _from, %{connection: connection, status: :connected} = state) do
    :dbus_connection.close(connection)
    {:reply, :ok, %{state | connection: nil, status: :disconnected}}
  end

  def handle_call(:disconnect, _from, state) do
    {:reply, {:error, "Not connected"}, state}
  end

  def handle_call(
        {:call_method, destination, path, interface, method, {_signature, _types, _body} = args},
        _from,
        %{status: :connected, connection: conn} = state
      ) do
    reply = call_method(destination, path, interface, method, args, conn)
    {:reply, reply, state}
  end

  defp call_method(destination, path, interface, method, {signature, types, body}, conn) do
    msg = :dbus_message.call(destination, path, interface, method)

    case :dbus_message.set_body(signature, types, body, msg) do
      {:error, _} = error ->
        error

      msg ->
        case :dbus_connection.call(conn, msg) do
          {:ok, {_, _, :undefined}} ->
            {:ok, nil}

          {:ok, {_, _, response}} ->
            {:ok, response}

          {:error, {_, header, body}} ->
            error_name = ErlangDBus.Message.find_field(:error_name, header)

            {:error, {error_name, body}}
        end
    end
  end

  def handle_call(
        {:introspect, destination, path},
        _from,
        %{status: :connected, connection: conn} = state
      ) do
    reply = introspect(destination, path, conn)
    {:reply, reply, state}
  end

  def handle_call(
        {:has_service, destination},
        _from,
        %{status: :connected, connection: conn} = state
      ) do
    result =
      call_method(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "GetNameOwner",
        {"s", [:string], [destination]},
        conn
      )

    {:reply, result, state}
  end

  def handle_call(
        {:find_object, destination, path},
        from,
        %{status: :connected, connection: conn} = state
      ) do
    result = find_object(destination, path, conn)
    {:reply, result, state}
  end

  def handle_call(
        {:has_object, destination, path},
        from,
        %{status: :connected, connection: conn} = state
      ) do
    case find_object(destination, path, conn) do
      {:ok, nil} -> {:reply, {:ok, false}, state}
      {:ok, _} -> {:reply, {:ok, true}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:has_interface, destination, path, interface},
        from,
        %{status: :connected, connection: conn} = state
      ) do
    case find_interface(destination, path, interface, conn) do
      {:ok, nil} -> {:reply, {:ok, false}, state}
      {:ok, _} -> {:reply, {:ok, true}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:register_service, service_name, service_pid},
        _from,
        %{bus: bus, connection: connection, status: :connected} = state
      ) do
    msg =
      :dbus_message.call(
        "org.freedesktop.DBus",
        "/",
        "org.freedesktop.DBus",
        "RequestName"
      )

    case :dbus_message.set_body("su", [:string, :uint32], [service_name, 0], msg) do
      {:error, error} -> raise error
      msg -> :dbus_connection.call(connection, msg)
    end

    {:reply, :ok, state}
  end

  def handle_call({:register_service, _name, _pid}, _from, state) do
    {:reply, {:error, "Bus not connected"}, state}
  end

  defp __connect(bus_id, service_name, state) when is_binary(service_name) do
    {:ok, service} = :dbus_service.start_link(service_name)
    {:ok, state} = __connect(bus_id, service, state)
    {:ok, state}
  end

  defp __connect(bus_id, service, state) when is_pid(service) do
    case :dbus_bus_connection.connect(bus_id, service) do
      {:ok, connection} ->
        {:ok, %{state | connection: connection, service: service, status: :connected}}

      error ->
        error
    end
  end

  defp __connect(bus_id, _, state) do
    case :dbus_bus_connection.connect(bus_id) do
      {:ok, connection} ->
        {:ok, %{state | connection: connection, status: :connected}}

      error ->
        error
    end
  end

  defp can_connect?(%{status: status}) when status in [:init, :disconnected] do
    true
  end

  defp can_connect?(_) do
    false
  end

  defp introspect(destination, "", conn) do
    introspect(destination, "/", conn)
  end

  defp introspect(destination, path, conn) do
    result =
      call_method(
        destination,
        path,
        "org.freedesktop.DBus.Introspectable",
        "Introspect",
        {"", [], []},
        conn
      )

    case result do
      {:ok, body} when is_binary(body) ->
        Saxy.SimpleForm.parse_string(body)

      {:ok, nil} ->
        {:error, "Empty body"}

      reply ->
        reply
    end
  end

  defp find_object(destination, "", conn) do
    find_object(destination, "/", "", conn)
  end

  defp find_object(destination, "/", conn) do
    find_object(destination, "/", "", conn)
  end

  defp find_object(destination, "/" <> _ = path, conn) do
    paths = String.split(path, "/", trim: true)

    case paths do
      [] ->
        find_object(destination, "/", "", conn)

      list ->
        last = List.last(list)
        list = list |> Enum.drop(-1) |> Enum.join("/")
        prefix = "/" <> list
        find_object(destination, prefix, last, conn)
    end
  end

  defp find_object(destination, "/", "", conn) do
    case introspect(destination, "/", conn) do
      {:ok, {"node", _, _} = node} -> {:ok, node}
      {:ok, _} -> {:ok, nil}
      error -> error
    end
  end

  defp find_object(destination, "/" <> _ = root, "", conn) do
    introspect(destination, root, conn)
  end

  defp find_object(destination, "/" <> _ = root, name, conn) do
    case introspect(destination, root, conn) do
      {:ok, {"node", _, children}} ->
        case __find_node(children, name) do
          nil ->
            {:ok, nil}

          _ ->
            path =
              if root == "/" do
                root <> name
              else
                root <> "/" <> name
              end

            find_object(destination, path, "", conn)
        end

      {:ok, _} ->
        {:ok, nil}

      error ->
        error
    end
  end

  defp find_interface(destination, path, interface, conn) do
    with {:ok, child} <- find_object(destination, path, conn) do
      case child do
        {"node", _, children} -> {:ok, __find_interface(children, interface)}
        any -> {:ok, nil}
      end
    end
  end

  defp __find_node(list, name) do
    __find_child("node", list, name)
  end

  defp __find_interface(list, name) do
    __find_child("interface", list, name)
  end

  defp __find_child(_tag, [], _name) do
    nil
  end

  defp __find_child(tag, [{tag, _, _}] = child, "") do
    child
  end

  defp __find_child(tag, [{tag, attrs, _} = child | list], name) do
    if Enum.any?(attrs, &match?({"name", ^name}, &1)) do
      child
    else
      __find_child(tag, list, name)
    end
  end

  defp __find_child(tag, [_ | list], name) do
    __find_child(tag, list, name)
  end

  defp __find_child(_, _, _) do
    nil
  end
end
