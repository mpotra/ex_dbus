defmodule ExDBus.Router do
  alias ExDBus.Spec

  @callback method(
              path :: String.t(),
              interface :: String.t(),
              method :: String.t(),
              signature :: String.t(),
              args :: list(),
              context :: map()
            ) ::
              Spec.method_handle_return() | :skip
  @callback get_property(
              path :: String.t(),
              interface :: String.t(),
              property :: String.t(),
              context :: map()
            ) ::
              Spec.property_getter_return() | :skip
  @callback set_property(
              path :: String.t(),
              interface :: String.t(),
              property :: String.t(),
              value :: any(),
              context :: map()
            ) ::
              Spec.property_setter_return() | :skip

  defmacro __using__(_opts) do
    quote do
      @behaviour ExDBus.Router

      defimpl ExDBus.Router.Protocol, for: __MODULE__ do
        def method(_, path, interface, method, signature, args, context) do
          @for.method(path, interface, method, signature, args, context)
        end

        def get_property(_, path, interface, property, context) do
          @for.get_property(path, interface, property, context)
        end

        def set_property(_, path, interface, property, value, context) do
          @for.set_property(path, interface, property, value, context)
        end
      end
    end
  end
end
