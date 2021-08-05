defmodule ExDBus.Spec do
  @type name() :: String.t()
  @type dbus_type() :: any()
  @type access() :: :readwrite | :write | :read
  @type direction() :: :in | :out
  @type object_child() :: object() | interface()
  @type interface_child() :: object() | member()
  @type member_child() :: argument() | annotation()
  @type annotation_value() :: String.t() | boolean() | number()
  @type method_handle() :: (... -> any())
  @type setter() :: (any() -> any())
  @type getter() :: (() -> any())
  @type property_handle() :: {getter :: getter(), setter :: setter()}
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
        @type spec_access() :: Spec.access()
        @type spec_direction() :: Spec.direction()
        @type spec_annotation_value() :: Spec.annotation_value()
        @type spec_method_handle() :: Spec.method_handle()
        @type spec_property_handle() :: Spec.property_handle()
        @type spec_service() :: Spec.service()
        @type spec_object() :: Spec.object()
        @type spec_interface() :: Spec.interface()
        @type spec_method() :: Spec.method()
        @type spec_signal() :: Spec.signal()
        @type spec_property() :: Spec.property()
        @type spec_annotation() :: Spec.annotation()
        @type spec_argument() :: Spec.argument()
        @type spec_member() :: Spec.member()
        @type spec_property_getter() :: Spec.getter()
        @type spec_property_setter() :: Spec.setter()
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
        @type access() :: Spec.access()
        @type direction() :: Spec.direction()
        @type annotation_value() :: Spec.annotation_value()
        @type method_handle() :: Spec.method_handle()
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
        @type property_getter() :: Spec.getter()
        @type property_setter() :: Spec.setter()
        @type element() :: Spec.element()
        @type definition() :: Spec.definition()
        @type tag() :: Spec.tag()
      end
    end
  end
end
