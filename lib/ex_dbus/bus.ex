defmodule ExDBus.Bus do
  use GenServer
  @type bus_pid() :: pid()
  @type bus_id() :: :session | :system
  @type status() :: :init | :connected | :disconnected

  defmodule State do
    alias ExDBus.Bus

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

  @spec start_link(bus_id(), keyword()) :: GenServer.on_start()
  def start_link(bus_id, opts \\ []) do
    GenServer.start_link(__MODULE__, bus_id, opts)
  end

  @spec connect(bus_pid() | bus_id() | module(), pid() | nil | String.t()) ::
          :ok | :ignore | {:error, term()}
  def connect(bus_pid \\ __MODULE__, service \\ nil)

  def connect(bus_id, service) when bus_id in [:session, :system] do
    case start_link(bus_id) do
      {:ok, bus_pid} ->
        case connect(bus_pid, service) do
          :ok ->
            {:ok, bus_pid}

          error ->
            GenServer.stop(bus_pid, :normal, 0)
            error
        end

      error ->
        error
    end
  end

  def connect(bus_pid, service) do
    GenServer.call(bus_pid, {:connect, service})
  end

  @spec close(bus_pid() | module()) :: :ok | :ignore | {:error, term()}
  def close(bus_pid \\ __MODULE__) do
    GenServer.call(bus_pid, :disconnect)
  end

  @spec register_service(pid(), String.t(), pid()) :: :ok | :ignore | {:error, term()}
  def register_service(bus_pid, service_name, server_pid) do
    GenServer.call(bus_pid, {:register_service, service_name, server_pid})
  end

  @spec name_has_owner(pid(), String.t()) :: boolean()
  def name_has_owner(bus_pid, service_name) do
    case GenServer.call(bus_pid, {:name_has_owner, service_name}) do
      {:ok, true} -> true
      _ -> false
    end
  end

  @spec get_name_owner(pid(), String.t()) :: binary() | nil
  def get_name_owner(bus_pid, service_name) do
    case GenServer.call(bus_pid, {:get_name_owner, service_name}) do
      {:ok, owner} -> owner
      _ -> nil
    end
  end

  @spec list_names(pid()) :: list(String.t())
  def list_names(bus_pid) do
    case GenServer.call(bus_pid, :list_names) do
      {:ok, names} -> names
      _ -> []
    end
  end

  @spec has_interface?(pid(), String.t(), String.t(), String.t()) :: boolean()
  def has_interface?(bus_pid, service_name, path, interface_name) do
    case GenServer.call(bus_pid, {:has_interface, service_name, path, interface_name}) do
      {:ok, true} -> true
      _ -> false
    end
  end

  @spec register_name(pid(), String.t()) :: :ok | {:error, any()}
  def register_name(bus_pid, service_name) do
    GenServer.call(bus_pid, {:register_name, service_name})
  end

  @spec get_dbus_pid(pid()) :: {:ok, String.t()} | {:error, any()}
  def get_dbus_pid(bus_pid) do
    GenServer.call(bus_pid, :get_dbus_pid)
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
  def handle_call({:connect, service}, _from, %{id: bus_id} = state) do
    if can_connect?(state) do
      case __connect(bus_id, service, state) do
        {:ok, state} ->
          {:reply, :ok, state}

        error ->
          {:reply, error, state}
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
    result = _get_name_owner(conn, destination)

    {:reply, result, state}
  end

  def handle_call(
        {:find_object, destination, path},
        _from,
        %{status: :connected, connection: conn} = state
      ) do
    result = find_object(destination, path, conn)
    {:reply, result, state}
  end

  def handle_call(
        {:has_object, destination, path},
        _from,
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
        _from,
        %{status: :connected, connection: conn} = state
      ) do
    case find_interface(destination, path, interface, conn) do
      {:ok, nil} -> {:reply, {:ok, false}, state}
      {:ok, _} -> {:reply, {:ok, true}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(
        {:register_name, service_name},
        _from,
        %{bus: _bus, connection: conn, status: :connected} = state
      ) do
    #     with msg <-
    #       :dbus_message.call(
    #         "org.freedesktop.DBus",
    #         "/",
    #         "org.freedesktop.DBus",
    #         "RequestName"
    #       ),
    #     {:dbus_message, _, _} = msg <-
    #       :dbus_message.set_body("su", [:string, :uint32], [service_name, 0], msg),
    #     {:ok, _} <- :dbus_connection.call(conn, msg) do
    #  {:reply, :ok, state}
    # else
    #  error -> {:reply, error, state}
    # end

    reply =
      call_method(
        "org.freedesktop.DBus",
        "/",
        "org.freedesktop.DBus",
        "RequestName",
        {"su", [:string, :uint32], [service_name, 0]},
        conn
      )

    case reply do
      {:ok, _} -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:register_name, _name}, _from, state) do
    {:reply, {:error, "Bus not connected"}, state}
  end

  def handle_call({:name_has_owner, name}, _from, %{status: :connected, connection: conn} = state) do
    result = _name_has_owner(conn, name)

    {:reply, result, state}
  end

  def handle_call({:get_name_owner, name}, _from, %{status: :connected, connection: conn} = state) do
    result = _get_name_owner(conn, name)

    {:reply, result, state}
  end

  def handle_call(:list_names, _from, %{status: :connected, connection: conn} = state) do
    result = _list_names(conn)

    {:reply, result, state}
  end

  def handle_call(:get_dbus_pid, _from, %{status: :connected, connection: conn} = state) do
    ret = :dbus_bus_connection.get_unique_name(conn)
    {:reply, ret, state}
  end

  def handle_call(_, _from, state) do
    {:reply, {:error, "Bus not connected"}, state}
  end

  @impl true
  def handle_cast(
        {:send_signal, path, interface, signal},
        %{status: :connected, connection: conn} = state
      ) do
    send_signal(conn, path, interface, signal)
    {:noreply, state}
  end

  def handle_cast(
        {:send_signal, path, interface, signal, {signature, types, args}},
        %{status: :connected, connection: conn} = state
      ) do
    send_signal(conn, path, interface, signal, {signature, types, args})
    {:noreply, state}
  end

  #
  # Private functions
  #

  defp __connect(bus_id, service_name, state) when is_binary(service_name) do
    case :dbus_service.start_link(service_name) do
      {:ok, service_pid} -> __connect(bus_id, service_pid, state)
      error -> error
    end
  end

  defp __connect(bus_id, service_pid, state) when is_pid(service_pid) do
    case :dbus_bus_connection.connect(bus_id, service_pid) do
      {:ok, connection} ->
        {:ok, %{state | connection: connection, service: service_pid, status: :connected}}

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

  defp call_method(destination, path, interface, method, {signature, types, body}, conn) do
    msg = :dbus_message.call(destination, path, interface, method)

    case ErlangDBus.Message.set_body(signature, types, body, msg) do
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

  defp send_signal(conn, path, interface, signal) do
    send_signal(conn, path, interface, signal, nil)
  end

  defp send_signal(conn, path, interface, signal, {signature, types, args}) do
    send_signal(conn, path, interface, signal, {signature, types, args}, nil)
  end

  defp send_signal(conn, path, interface, signal, destination) do
    send_signal(conn, path, interface, signal, {nil, [], []}, destination)
  end

  defp send_signal(conn, path, interface, signal, {signature, types, args}, destination) do
    # Message = dbus_message:signal(undefined, Path, IfaceName, Signal, Args),
    # signal = {:dbus_signal, signal, [], :none, :undefined, types, []}

    try do
      # :dbus_message.signal(destination, path, interface, signal, args)
      ErlangDBus.Message.signal(destination, path, interface, signal, {signature, types, args})
    rescue
      e ->
        {:error, e}
    else
      {:ok, msg} ->
        :dbus_connection.cast(conn, msg)
    end
  end

  defp _name_has_owner(conn, name) do
    call_method(
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "NameHasOwner",
      {"s", [:string], [name]},
      conn
    )
  end

  defp _get_name_owner(conn, name) do
    call_method(
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "GetNameOwner",
      {"s", [:string], [name]},
      conn
    )
  end

  defp _list_names(conn) do
    call_method(
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "ListNames",
      {"", [], []},
      conn
    )
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
        _ -> {:ok, nil}
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
