defmodule ExDBus.Error do
  import Kernel, except: [defexception: 1]

  Kernel.defexception([:type])

  defmacro __using__(opts) do
    error_type = Keyword.get(opts, :type, nil)

    if error_type in ["", nil] do
      raise "Exception must have a name"
    end

    Module.register_attribute(__CALLER__.module, :error_type, accumulate: false, persist: true)
    Module.put_attribute(__CALLER__.module, :error_type, error_type)

    quote do
      import Kernel, except: [defexception: 1]
      import ExDBus.Error, only: [defexception: 1]

      def get_type() do
        @error_type
      end

      @impl true
      def message(exception) do
        "#{exception.type}"
      end

      def message(%{type: type, message: message}) when is_binary(message) and message != "" do
        "#{type}: #{message}"
      end

      defoverridable message: 1
    end
  end

  defmacro defexception(fields) do
    type = Module.get_attribute(__CALLER__.module, :error_type, "")

    fields = [message: ""] ++ fields ++ [type: type]

    quote do
      Kernel.defexception(unquote(fields))
    end
  end

  @impl true
  def message(exception) do
    "#{exception.type}"
  end

  def get_type(exception) do
    exception.type
  end
end

defmodule ExDBus.Error.Failed do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.Failed"
  defexception []
end

defmodule ExDBus.Error.UnknownObject do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.UnknownObject"
  defexception path: "/"

  @impl true
  def message(exception) do
    "#{exception.type}: Object \"#{exception.path}\" doesn't exist"
  end
end

defmodule ExDBus.Error.UnknownInterface do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.UnknownInterface"
  defexception [:interface, path: "/"]

  @impl true
  def message(exception) do
    "#{exception.type}: Interface \"#{exception.interface}\" under object \"#{exception.path}\" doesn't exist"
  end
end

defmodule ExDBus.Error.UnknownSignal do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.UnknownSignal"
  defexception [:interface, :signal, path: "/"]

  @impl true
  def message(exception) do
    "#{exception.type}: Signal \"#{exception.signal}\" in interface \"#{exception.interface}\" under object \"#{exception.path}\" doesn't exist"
  end
end

defmodule ExDBus.Error.UnknownMethod do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.UnknownMethod"
  defexception [:interface, :method, :signature, path: "/"]

  @impl true
  def message(exception) do
    "#{exception.type}: Method \"#{exception.method}\" with signature \"#{exception.signature}\" in interface \"#{exception.interface}\" under object \"#{exception.path}\" doesn't exist"
  end
end

defmodule ExDBus.Error.UnknownProperty do
  use ExDBus.Error, type: "org.freedesktop.DBus.Error.UnknownProperty"
  defexception [:interface, :property, path: "/"]

  @impl true
  def message(exception) do
    "#{exception.type}: Property \"#{exception.property}\" in interface \"#{exception.interface}\" under object \"#{exception.path}\" doesn't exist"
  end
end
