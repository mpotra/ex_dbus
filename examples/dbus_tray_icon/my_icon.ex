defmodule MyIcon.Config do
  use GenServer
  alias ExDBus.Tree

  def init(%{} = props) do
    {:ok, props}
  end

  @impl true
  def handle_call({:get_property, key}, _from, state) do
    if Map.has_key?(state, key) do
      {:reply, Map.get(state, key), state}
    else
      {:reply, {:error, "org.freedesktop.DBus.UnknownProperty", "Invalid property"}, state}
    end
  end

  def handle_call({:set_property, key, value}, _from, state) do
    state = Map.put(state, key, value)
    {:reply, :ok, state}
  end

  def handle_call(
        {:method, "GetLayout", {0, -1, ["type", "children-display"]}, _context},
        _from,
        state
      ) do
    # Signature: u(ia{sv}av)
    # result = [
    #   # u
    #   0,
    #   # (
    #   # i
    #   [
    #     0,
    #     # a
    #     [
    #       # a
    #       # {sv}
    #       ["label", ["s", "Label Empty"]],
    #       ["visible", ["b", 1]],
    #       ["enabled", ["b", 1]],
    #       ["children-display", ["s", "submenu"]]
    #     ],
    #     # a
    #     [
    #       # v
    #       [
    #         "(ia{sv}av)",
    #         # (
    #         [
    #           # i
    #           75,
    #           # a
    #           [
    #             # {sv}
    #             ["label", ["s", "_File"]],
    #             ["visible", ["b", 1]],
    #             ["enabled", ["b", 1]],
    #             ["children-display", ["s", "submenu"]]
    #           ],
    #           # av
    #           []
    #         ]
    #       ]
    #     ]
    #   ]
    # ]

    # "(ia{sv}av)"
    dbus_menu_item_type = {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

    children = [
      {:dbus_variant, dbus_menu_item_type,
       {
         1,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "File"}},
           {"children-display", {:dbus_variant, :string, "submenu"}}
         ],
         []
       }},
      {:dbus_variant, dbus_menu_item_type,
       {
         2,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "View"}},
           {"children-display", {:dbus_variant, :string, "submenu"}}
         ],
         []
       }},
      {:dbus_variant, dbus_menu_item_type,
       {
         3,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "Quit"}},
           {"children-display", {:dbus_variant, :string, ""}}
         ],
         []
       }}
    ]

    menu = {
      0,
      [
        {"enabled", {:dbus_variant, :boolean, true}},
        {"visible", {:dbus_variant, :boolean, true}},
        {"type", {:dbus_variant, :string, "standard"}},
        {"children-display", {:dbus_variant, :string, "submenu"}}
      ],
      children
    }

    reply = {:ok, [:uint32, dbus_menu_item_type], [0, menu]}

    {:reply, reply, state}
  end

  def handle_call(
        {:method, "AboutToShow", _args, _context},
        _from,
        state
      ) do
    {:reply, {:ok, [:boolean], [false]}, state}
  end

  def handle_call({:method, "Activate", _args, _context}, _from, state) do
    {:reply, {:ok, [], []}, state}
  end

  def handle_call({:method, method_name, args, context}, _from, state) do
    IO.inspect({method_name, args}, label: "[MyIcon.Config] METHOD call")

    {:reply,
     {:error, "org.freedesktop.DBus.Error.UnknownMethod",
      "Method (#{method_name}) not found on given interface"}, state}
  end
end

defmodule MyIcon.Router do
  def method(path, interface, method, signature, args, context) do
    IO.inspect(
      [
        path,
        interface,
        method,
        signature,
        args,
        context
      ],
      label: "ROUTE METHOD"
    )

    :skip
  end

  def get_property(path, interface, property, context) do
    IO.inspect(
      [
        path,
        interface,
        property,
        context
      ],
      label: "ROUTE GET PROPERTY"
    )

    :skip
  end
end

defmodule MyIcon do
  use GenServer
  # require ExDBus.DBusTrayIcon.IconSchema

  def register_icon(pid \\ __MODULE__) do
    GenServer.call(pid, :register_icon)
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      [],
      opts
    )
  end

  @impl true
  def init(_opts) do
    name = "org.example.MyIcon-#{:os.getpid()}-1"

    {:ok, service} =
      ExDBus.Service.start_link(
        name,
        DBusTrayIcon.IconSchema,
        router: MyIcon.Router
      )

    bus = ExDBus.Service.get_bus(service)
    :ok = can_register(bus)

    # pixdata = gen_icon(128, 128)

    {:ok, icon} =
      GenServer.start_link(MyIcon.Config, %{
        "Category" => "ApplicationStatus",
        "Id" => "1",
        "Title" => "test_icon",
        "Menu" => "/MenuBar",
        "Status" => "Active",
        "IconName" => "applications-development",
        "OverlayIconName" => "",
        "AttentionIconName" => "",
        "AttentionMovieName" => "",
        "ToolTip" => [
          {:dbus_variant, :string, "applications-development"},
          [],
          {:dbus_variant, :string, "test tooltip"},
          {:dbus_variant, :string, "some tooltip description here"}
        ],
        "ItemIsMenu" => false,
        "IconPixmap" => [],
        "OverlayIconPixmap" => [],
        "AttentionIconPixmap" => [],
        "WindowId" => 0
      })

    :ok = setup_interface({"/StatusNotifierItem", "org.kde.StatusNotifierItem"}, service, icon)

    {:ok, menu} =
      GenServer.start_link(MyIcon.Config, %{
        "Version" => 3,
        "TextDirection" => "ltr",
        "Status" => "normal",
        "IconThemePath" => []
      })

    :ok = setup_interface({"/MenuBar", "com.canonical.dbusmenu"}, service, menu)

    state = %{service: service, name: name, menu: menu, icon: icon}

    {:ok, state}
  end

  # Gen server implementation

  @impl true
  # def handle_call({:get_object, path}, _from, %{service: service} = state) do
  #   {:reply, GenServer.call(service, {:get_object, path}), state}
  # end

  # def handle_call({:get_interface, path, name}, _from, %{service: service} = state) do
  #   {:reply, GenServer.call(service, {:get_interface, path, name}), state}
  # end

  # def handle_call({:replace_interface, path, interface}, _from, %{service: service} = state) do
  #   {:reply, GenServer.call(service, {:replace_interface, path, interface}), state}
  # end

  # def handle_call(:setup, _from, state) do
  #   {:reply, setup_interface(state), state}
  # end

  def handle_call(:register_icon, from, %{service: service, name: service_name} = state) do
    reply =
      GenServer.call(service, {
        :call_method,
        "org.kde.StatusNotifierWatcher",
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher",
        "RegisterStatusNotifierItem",
        {"s", [:string], [service_name]}
      })
      |> IO.inspect(label: "REGISTER ICON CALL")

    {:reply, reply, state}
  end

  def handle_call(request, from, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(request, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    {:noreply, state}
  end

  defp can_register(bus) do
    with :ok <- has_status_notifier(bus) do
      :ok
    end
  end

  defp has_status_notifier(bus) do
    owner_result =
      GenServer.call(
        bus,
        {:call_method, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
         "GetNameOwner", {"s", [:string], ["org.kde.StatusNotifierWatcher"]}}
      )

    iface_result =
      GenServer.call(
        bus,
        {:has_interface, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
         "org.kde.StatusNotifierWatcher"}
      )

    with {:ok, _} <- owner_result,
         {:ok, true} <- iface_result do
      :ok
    else
      {:ok, _} -> {:error, "Could not find valid StatusNotifierWatcher"}
      error -> error
    end
  end

  defp setup_interface({path, interface_name}, service, handle) do
    {:ok, {:interface, _, children}} =
      GenServer.call(
        service,
        {:get_interface, path, interface_name}
      )

    prop_getter = {:call, handle, :get_property}
    prop_setter = {:call, handle, :set_property}
    method_callback = {:call, handle, :method}

    children =
      children
      |> Enum.map(fn child ->
        case ExDBus.Tree.get_tag(child) do
          :property ->
            if elem(child, 1) == "Status" do
              child
            else
              child
              |> ExDBus.Tree.set_property_setter(prop_setter)
              |> ExDBus.Tree.set_property_getter(prop_getter)
            end

          :method ->
            if elem(child, 1) == "Event" do
              child
            else
              child
              |> ExDBus.Tree.set_method_callback(method_callback)
            end

          _ ->
            child
        end
      end)

    :ok =
      GenServer.call(
        service,
        {:replace_interface, path, {:interface, interface_name, children}}
      )

    :ok
  end

  # Generate icon
  def gen_icon(width, height) do
    lines = height

    Enum.reduce(0..width, [], fn _, buf ->
      add_line(buf, {155, 255, 0, 255}, height)
    end)
  end

  def add_line(buf, pixel, 0) do
    buf
  end

  def add_line(buf, pixel, index) do
    add_line(add_pixel(buf, pixel), pixel, index - 1)
  end

  def add_pixel(buf, {a, r, g, b}) do
    [a | [r | [g | [b | buf]]]]
  end

  # def __register_icon(pid) do
  #       service_name = "org.example.MyIcon"

  #       {:ok, bus} =
  #         :dbus_bus_reg.get_bus(:session)
  #         |> IO.inspect(label: ":dbus_bus_reg.get_bus(:session)")

  #       {:ok, service} =
  #         :dbus_bus.get_service(bus, "org.kde.StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_bus.get_service")

  #       {:ok, object} =
  #         :dbus_remote_service.get_object(service, "/StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_remote_service.get_object")

  #       {:ok, interface} =
  #         :dbus_proxy.interface(object, "org.kde.StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_proxy.interface")

  #       :ok =
  #         :dbus_proxy.call(
  #           interface,
  #           "RegisterStatusNotifierItem",
  #           [service_name]
  #         )
  #         |> IO.inspect(label: ":dbus_proxy.call")

  #       IO.inspect(:os.getpid(), label: "[REGISTER ICON]")

  #       # :ok = :dbus_remote_service.release_object(service, object)
  #       # :ok = :dbus_bus.release_service(bus, service)
  #     end
end
