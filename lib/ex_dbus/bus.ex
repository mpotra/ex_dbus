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
        {:call_method, destination, path, interface, method, {signature, types, body}},
        from,
        %{status: :connected, connection: conn} = state
      ) do
    msg = :dbus_message.call(destination, path, interface, method)

    case :dbus_message.set_body(signature, types, body, msg) do
      {:error, err} ->
        {:reply, {:error, err}, state}

      msg ->
        case :dbus_connection.call(conn, msg) do
          {:ok, {_, _, :undefined}} ->
            {:reply, {:ok, nil}, state}

          {:ok, {_, _, response}} ->
            {:reply, {:ok, response}, state}

          {:error, {_, _, body}} ->
            code = ErlangDBus.Message.get_field(:error_name, body)
            {:reply, {:throw, String.to_atom(code)}, state}
        end
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
end
