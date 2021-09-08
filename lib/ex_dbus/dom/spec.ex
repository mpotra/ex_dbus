defmodule ExDBus.Spec do
  @type name() :: String.t()
  @type dbus_type() :: any()
  @type dbus_reply_error() :: {:error, binary(), binary()}
  @type dbus_reply_ok() :: {:ok, list(atom()), list()}
  @type dbus_reply() :: dbus_reply_ok() | dbus_reply_error()
  @type access() :: :readwrite | :write | :read
  @type direction() :: :in | :out
  @type object_child() :: object() | interface()
  @type interface_child() :: object() | member()
  @type member_child() :: argument() | annotation()
  @type annotation_value() :: String.t() | boolean() | number()
  @type method_handle_return() ::
          :skip | dbus_reply()
  @type method_handle_base_arg() :: binary() | number()
  @type method_handle_arg() :: tuple() | method_handle_base_arg()
  @type method_handle() ::
          (args :: method_handle_arg(), context :: map() -> method_handle_return())
          | {:call, pid(), atom()}
          | nil
  @type property_getter_return() ::
          :skip | {:ok, any()} | dbus_reply_error()
  @type property_setter_return() ::
          :skip | {:ok, any()} | dbus_reply_error()
  @type property_setter() ::
          (property_name :: String.t(), value :: any() -> property_setter_return)
          | {:call, pid(), atom()}
          | nil
  @type property_getter() ::
          (property_name :: String.t() -> property_getter_return())
          | {:call, pid(), atom()}
          | nil
  @type property_handle() :: {getter :: property_getter(), setter :: property_setter()} | nil
  @type index() :: -1 | non_neg_integer()
  @type tag() ::
          :service
          | :object
          | :interface
          | :method
          | :signal
          | :property
          | :annotation
          | :argument

  @type service() :: {:service, name :: name(), children :: list(object())}
  @type object() :: {:object, name :: name(), children :: list(object_child())}
  @type interface() :: {:interface, name :: name(), children :: list(interface_child())}
  @type method() ::
          {:method, name :: name(), children :: list(member_child()), handle :: method_handle()}
  @type signal() :: {:signal, name :: name(), children :: list(member_child())}
  @type property() ::
          {:property, name :: name(), type :: dbus_type(), access :: access(),
           annotations :: list(annotation()), handle :: property_handle()}
  @type annotation() :: {:annotation, name :: name(), value :: annotation_value()}
  @type argument() ::
          {:argument, name :: name(), type :: dbus_type(), direction :: direction(),
           annotations :: list(annotation())}
  @type member() :: method() | signal() | property() | annotation()

  @type element() :: object() | interface() | member()
  @type definition() :: element() | argument()

  defmacro __using__(opts) do
    if Keyword.get(opts, :prefix, true) do
      quote do
        alias ExDBus.Spec

        @type spec_index() :: Spec.index()
        @type spec_name() :: Spec.name()
        @type spec_dbus_type() :: Spec.dbus_type()
        @type spec_dbus_reply_error() :: Spec.dbus_reply_error()
        @type spec_dbus_reply_ok() :: Spec.dbus_reply_ok()
        @type spec_dbus_reply() :: Spec.dbus_reply()
        @type spec_access() :: Spec.access()
        @type spec_direction() :: Spec.direction()
        @type spec_annotation_value() :: Spec.annotation_value()
        @type spec_method_handle() :: Spec.method_handle()
        @type spec_property_handle() :: Spec.property_handle()
        @type spec_service() :: Spec.service()
        @type spec_object() :: Spec.object()
        @type spec_interface() :: Spec.interface()
        @type spec_method() :: Spec.method()
        @type spec_method_handle() :: Spec.method_handle()
        @type spec_method_handle_return() :: Spec.method_handle_return()
        @type spec_signal() :: Spec.signal()
        @type spec_property() :: Spec.property()
        @type spec_annotation() :: Spec.annotation()
        @type spec_argument() :: Spec.argument()
        @type spec_member() :: Spec.member()
        @type spec_property_getter() :: Spec.property_getter()
        @type spec_property_setter() :: Spec.property_setter()
        @type spec_property_getter_return() :: Spec.property_getter_return()
        @type spec_property_setter_return() :: Spec.property_setter_return()
        @type spec_element() :: Spec.element()
        @type spec_definition() :: Spec.definition()
        @type spec_tag() :: Spec.tag()
      end
    else
      quote do
        alias ExDBus.Spec

        @type index() :: Spec.index()
        @type name() :: Spec.name()
        @type dbus_type() :: Spec.dbus_type()
        @type dbus_reply_error() :: Spec.dbus_reply_error()
        @type dbus_reply_ok() :: Spec.dbus_reply_ok()
        @type dbus_reply() :: Spec.dbus_reply()
        @type access() :: Spec.access()
        @type direction() :: Spec.direction()
        @type annotation_value() :: Spec.annotation_value()
        @type method_handle() :: Spec.method_handle()
        @type method_handle_return() :: Spec.method_handle_return()
        @type property_handle() :: Spec.property_handle()
        @type service() :: Spec.service()
        @type object() :: Spec.object()
        @type interface() :: Spec.interface()
        @type method() :: Spec.method()
        @type signal() :: Spec.signal()
        @type property() :: Spec.property()
        @type annotation() :: Spec.annotation()
        @type argument() :: Spec.argument()
        @type member() :: Spec.member()
        @type property_getter() :: Spec.property_getter()
        @type property_setter() :: Spec.property_setter()
        @type property_getter_return() :: Spec.property_getter_return()
        @type property_setter_return() :: Spec.property_setter_return()
        @type element() :: Spec.element()
        @type definition() :: Spec.definition()
        @type tag() :: Spec.tag()
      end
    end
  end
end
