defmodule ErlangDBus.Service do
  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_info({:dbus_method_call, msg, conn}, state) do
        path = ErlangDBus.Message.get_field(:path, msg)
        IO.inspect(msg, label: "[INFO] message")
        # handle_method_call(path, msg, conn, state)
      end
    end
  end
end
