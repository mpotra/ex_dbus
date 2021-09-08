defmodule ExDBus.Router do
  alias ExDBus.Spec
  @type return() :: Spec.dbus_reply() | :skip
  @callback method(
              path :: String.t(),
              interface :: String.t(),
              method :: String.t(),
              signature :: String.t(),
              args :: list(),
              context :: map()
            ) ::
              return()
  @callback get_property(
              path :: String.t(),
              interface :: String.t(),
              property :: String.t(),
              context :: map()
            ) ::
              return()
  @callback set_property(
              path :: String.t(),
              interface :: String.t(),
              property :: String.t(),
              value :: any(),
              context :: map()
            ) ::
              return()

  defmacro __using__(_opts) do
    quote do
      @behaviour ExDBus.Router
    end
  end
end
