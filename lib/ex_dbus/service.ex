defmodule ExDBus.Service do
  alias ExDBus.Builder

  defmacro __using__(opts) do
    module = __CALLER__.module
    service_name = Keyword.get(opts, :service, nil)

    unless service_name != nil do
      raise ArgumentError, "Missing :service option"
    end

    service = Builder.service!(service_name)

    Module.register_attribute(module, :__service, accumulate: false, persist: false)
    Module.put_attribute(module, :__service, service)

    quote do
      use GenServer
      import Kernel, except: [node: 0, node: 1]
      import ExDBus.Schema, only: [node: 0, node: 1, node: 2]

      @before_compile ExDBus.Service

      def reply({pid, from}, reply) do
        GenServer.cast(pid, {:reply, from, reply})
      end

      def signal(signal, args) do
        signal(signal, args, [])
      end

      def signal(signal, args, options) do
        GenServer.cast(self(), {:signal, signal, args, options})
      end

      # @impl true
      # def init(stack) do
      #   {:ok, stack}
      # end

      # @impl true
      # def handle_call(:pop, _from, [head | tail]) do
      #   {:reply, head, tail}
      # end

      # @impl true
      # def handle_cast({:push, element}, state) do
      #   {:noreply, [element | state]}
      # end
    end
  end

  defmacro __before_compile__(env) do
    IO.inspect(env.module, label: "__BEFORE_COMPILE__")

    service = Module.get_attribute(env.module, :__service)

    service
    |> ExDBus.XML.Saxy.to_xml()
    |> Saxy.encode!()
    |> IO.inspect(label: "SERVICE XML")

    quote do
      @impl true
      def init(opts) do
        # {:ok, {service_name, path, dbus_config}, sub_state} ->
        #   {:ok, service} = :dbus_service_reg.export_service(service_name)
        #   :ok = :dbus_service.register_object(service, path, self())
        #   # state = #state{service=Service,
        #   #    path=path,
        #   #    module=module,
        #   #    sub=sub_state},
        #   # setup(dbus_config, state)
        # state = [
        #   service_name: unquote(opts_service),
        #   path: unquote(opts_path),
        #   module: __MODULE__
        # ]

        # {:ok, service} = :dbus_service_reg.export_service(unquote(service_name))
        # :ok = :dbus_service.register_object(service, unquote(path), self())

        # {:ok, state}
      end
    end
  end
end
