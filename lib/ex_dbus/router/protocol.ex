defprotocol ExDBus.Router.Protocol do
  alias ExDBus.Spec

  @spec method(
          t(),
          path :: String.t(),
          interface :: String.t(),
          method :: String.t(),
          signature :: String.t(),
          args :: list(),
          context :: map()
        ) ::
          Spec.method_handle_return() | :skip
  def method(router, path, interface, method, signature, args, context)

  @spec get_property(
          t(),
          path :: String.t(),
          interface :: String.t(),
          property :: String.t(),
          context :: map()
        ) ::
          Spec.property_getter_return() | :skip
  def get_property(router, path, interface, property, context)

  @spec set_property(
          t(),
          path :: String.t(),
          interface :: String.t(),
          property :: String.t(),
          value :: any(),
          context :: map()
        ) ::
          Spec.property_setter_return() | :skip
  def set_property(router, path, interface, property, value, context)
end
