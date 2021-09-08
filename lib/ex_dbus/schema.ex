defmodule ExDBus.Schema do
  alias ExDBus.Schema.Importing
  alias ExDBus.Builder

  defmacro __using__(_) do
    module = __CALLER__.module

    Module.register_attribute(module, :__schema_root__, accumulate: false, persist: false)
    Module.put_attribute(module, :__schema_root__, Builder.root!(""))

    quote do
      import Kernel, except: [node: 0, node: 1]
      import ExDBus.Schema, only: [node: 0, node: 1, node: 2]

      @before_compile ExDBus.Schema
    end
  end

  defmacro __before_compile__(env) do
    root = Module.get_attribute(env.module, :__schema_root__)

    # if Module.get_attribute(env.module, :inspect) == true do
    #   IO.inspect(root, label: "[ROOT OF #{env.module}]")
    # end

    escaped_root = Macro.escape(root)

    quote do
      def __schema__() do
        unquote(escaped_root)
      end
    end
  end

  defmacro node() do
    __def_node__(__CALLER__, "")
  end

  defmacro node(do: block) do
    __def_node__(__CALLER__, "", block)
  end

  defmacro node(name) do
    __def_node__(__CALLER__, name)
  end

  defmacro node(name, do: block) do
    __def_node__(__CALLER__, name, block)
  end

  defp __def_node__(_caller, name) do
    quote do
      root = Builder.root!(unquote(name))
      Module.put_attribute(__MODULE__, :__schema_root__, root)
    end
  end

  defp __def_node__(caller, name, block) do
    object = Macro.unique_var(:object, caller.module)
    block = Macro.prewalk(block, &parse_node(&1, object, caller))

    node_block =
      quote do
        unquote(object) = Builder.root!(unquote(name))
        unquote(block)
        unquote(object) = Builder.Reverse.reverse(unquote(object))
        Module.put_attribute(__MODULE__, :__schema_root__, unquote(object))
      end

    # File.write!("./#{caller.module}.instr.txt", Macro.to_string(node_block))

    node_block
  end

  defp parse_node({:interface, _meta, [name, [do: block]]}, parent, caller) do
    interface = Macro.unique_var(:interface, caller.module)
    block = Macro.prewalk(block, &parse_interface(&1, interface, caller))

    quote do
      unquote(interface) = Builder.interface!(unquote(name))

      if Builder.Finder.contains?(unquote(parent), unquote(interface)) do
        raise "Interface \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(block)

      unquote(interface) = Builder.Reverse.reverse(unquote(interface))

      unquote(parent) = Builder.Insert.insert!(unquote(parent), unquote(interface))
    end
  end

  defp parse_node({:node, _meta, [name]}, parent, caller) do
    object = Macro.unique_var(:object, caller.module)

    quote do
      # parent_object = object
      unquote(object) = Builder.object!(unquote(name))

      if Builder.Finder.contains?(unquote(parent), unquote(object)) do
        raise "Object \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(parent) = Builder.Insert.insert!(unquote(parent), unquote(object))
    end
  end

  defp parse_node({:node, _meta, [name, [do: block]]}, parent, caller) do
    object = Macro.unique_var(:object, caller.module)
    block = Macro.prewalk(block, &parse_node(&1, object, caller))

    quote do
      # parent_object = object
      unquote(object) = Builder.object!(unquote(name))

      if Builder.Finder.contains?(unquote(parent), unquote(object)) do
        raise "Object \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(block)

      unquote(object) = Builder.Reverse.reverse(unquote(object))

      unquote(parent) = Builder.Insert.insert!(unquote(parent), unquote(object))
    end
  end

  defp parse_node({:import, _, _} = ast, parent, caller) do
    Importing.parse_node(ast, parent, caller)
  end

  defp parse_node(ast, _parent, _caller) do
    ast
  end

  defp parse_interface({:interface, _meta, [_ | _]}, _interface, _caller) do
    raise "Cannot define interface in another interface"
  end

  defp parse_interface({:node, _meta, [_ | _]}, _interface, _caller) do
    raise "Cannot define node inside an interface"
  end

  defp parse_interface({:annotation, _, [_ | _]} = annotation, interface, caller) do
    block = process_annotation(annotation, interface, caller)

    quote do
      # parent = interface
      unquote(block)
      # interface = parent
    end
  end

  defp parse_interface({:method, _, [name, [do: block]]}, interface, caller) do
    method = Macro.unique_var(:method, caller.module)
    block = Macro.prewalk(block, &parse_method(&1, method, caller))

    quote do
      unquote(method) = Builder.method!(unquote(name))

      # parent = method
      unquote(block)
      unquote(method) = Builder.Reverse.reverse(unquote(method))

      # if Builder.Finder.contains?(interface, method) do
      #   raise "Method \"#{unquote(name)}\" already defined in parent node"
      # end

      unquote(interface) = Builder.Insert.insert!(unquote(interface), unquote(method))
    end
  end

  defp parse_interface({:method, _, [[do: _block]]}, _interface, _caller) do
    raise "Method definition requires a name argument"
  end

  defp parse_interface({:method, _, [_]}, _interface, _caller) do
    raise "Method definition requires a block"
  end

  defp parse_interface({:method, _, [_ | _]}, _interface, _caller) do
    raise "Method definition unsupported"
  end

  defp parse_interface({:signal, _, [name, [do: block]]}, interface, caller) do
    signal = Macro.unique_var(:signal, caller.module)
    block = Macro.prewalk(block, &parse_signal(&1, signal, caller))

    quote do
      unquote(signal) = Builder.signal!(unquote(name))

      if Builder.Finder.contains?(unquote(interface), unquote(signal)) do
        raise "Signal \"#{unquote(name)}\" already defined in interface"
      end

      # parent = signal
      unquote(block)
      unquote(signal) = Builder.Reverse.reverse(unquote(signal))

      unquote(interface) = Builder.Insert.insert!(unquote(interface), unquote(signal))
    end
  end

  defp parse_interface({:signal, _, [name]}, interface, caller) do
    signal = Macro.unique_var(:signal, caller.module)

    quote do
      unquote(signal) = Builder.signal!(unquote(name))

      if Builder.Finder.contains?(unquote(interface), unquote(signal)) do
        raise "Signal \"#{unquote(name)}\" already defined in interface"
      end

      unquote(interface) = Builder.Insert.insert!(unquote(interface), unquote(signal))
    end
  end

  defp parse_interface({:signal, _, [_ | _]}, _interface, _caller) do
    raise "Signal definition requires name and optional block"
  end

  defp parse_interface({:property, _, [name, type, access, [do: block]]}, interface, caller) do
    property = Macro.unique_var(:property, caller.module)
    block = Macro.prewalk(block, &parse_property(&1, property, caller))

    quote do
      unquote(property) = Builder.property!(unquote(name), unquote(type), unquote(access))

      if Builder.Finder.contains?(unquote(interface), unquote(property)) do
        raise "Property \"#{unquote(name)}\" already defined in interface"
      end

      # parent = property
      unquote(block)
      unquote(property) = Builder.Reverse.reverse(unquote(property))
      unquote(interface) = Builder.Insert.insert!(unquote(interface), unquote(property))
    end
  end

  defp parse_interface({:property, _, [name, type, access]}, interface, caller) do
    property = Macro.unique_var(:property, caller.module)

    quote do
      unquote(property) = Builder.property!(unquote(name), unquote(type), unquote(access))

      if Builder.Finder.contains?(unquote(interface), unquote(property)) do
        raise "Property \"#{unquote(name)}\" already defined in interface"
      end

      unquote(interface) = Builder.Insert.insert!(unquote(interface), unquote(property))
    end
  end

  defp parse_interface({:property, _, [_ | _]}, _interface, _caller) do
    raise "Property definition requires 3 arguments and optional block"
  end

  defp parse_interface(ast, _interface, _caller) do
    ast
  end

  # Signal children parsing functions

  defp parse_signal({:arg, meta, [name, type]}, signal, caller) do
    parse_signal({:arg, meta, [name, type, :out]}, signal, caller)
  end

  defp parse_signal({:arg, _, [name, type, :out]}, signal, _caller) do
    quote do
      argument = Builder.argument!(unquote(name), unquote(type), :out)
      unquote(signal) = Builder.Insert.insert!(unquote(signal), argument)
    end
  end

  defp parse_signal({:arg, meta, [name, type, [do: block]]}, signal, caller) do
    parse_signal({:arg, meta, [name, type, :out, [do: block]]}, signal, caller)
  end

  defp parse_signal({:arg, _, [name, type, :out, [do: block]]}, signal, caller) do
    argument = Macro.unique_var(:argument, caller.module)
    block = Macro.prewalk(block, &parse_argument(&1, argument, caller))

    quote do
      unquote(argument) = Builder.argument!(unquote(name), unquote(type), :out)
      # prev_parent = parent
      # parent = argument
      unquote(block)
      unquote(argument) = Builder.Reverse.reverse(unquote(argument))
      unquote(signal) = Builder.Insert.insert!(unquote(signal), unquote(argument))
    end
  end

  defp parse_signal({:arg, _, [_ | _]}, _signal, _caller) do
    raise "Signal argument definition requires 2 arguments, optional :out direction and optional block"
  end

  defp parse_signal({:annotation, _, [_ | _]} = annotation, signal, caller) do
    process_annotation(annotation, signal, caller)
  end

  defp parse_signal(ast, _signal, _caller) do
    ast
  end

  # Method children parsing functions

  defp parse_method({:arg, _, [name, type, direction]}, method, _caller) do
    quote do
      argument = Builder.argument!(unquote(name), unquote(type), unquote(direction))
      unquote(method) = Builder.Insert.insert!(unquote(method), argument)
    end
  end

  defp parse_method({:arg, _, [name, type, direction, [do: block]]}, method, caller) do
    argument = Macro.unique_var(:argument, caller.module)
    block = Macro.prewalk(block, &parse_argument(&1, argument, caller))

    quote do
      unquote(argument) = Builder.argument!(unquote(name), unquote(type), unquote(direction))
      # prev_parent = parent
      # parent = argument
      unquote(block)
      unquote(argument) = Builder.Reverse.reverse(unquote(argument))
      unquote(method) = Builder.Insert.insert!(unquote(method), unquote(argument))
    end
  end

  defp parse_method({:arg, _, [_ | _]}, _method, _caller) do
    raise "Method argument definition requires 3 arguments and optional block"
  end

  defp parse_method({:callback, _, [{:fn, _, _}]}, _method, _caller) do
    raise "Dynamic functions are not supported. Callbacks should be remote functions in the &Mod.fun/arity format"
  end

  defp parse_method({:callback, _, [callback]}, method, _caller) do
    quote do
      unquote(method) = Builder.set_method_callback!(unquote(method), unquote(callback))
    end
  end

  defp parse_method({:annotation, _, [_ | _]} = annotation, method, caller) do
    process_annotation(annotation, method, caller)
  end

  defp parse_method(ast, _method, _caller) do
    ast
  end

  # Property parsing functions
  defp parse_property({:getter, _, [{:fn, _, _}]}, _property, _caller) do
    raise "Dynamic functions are not supported. Callbacks should be remote functions in the &Mod.fun/arity format"
  end

  defp parse_property({:getter, _, [getter]}, property, _caller) do
    quote do
      unquote(property) = Builder.set_property_getter!(unquote(property), unquote(getter))
    end
  end

  defp parse_property({:setter, _, [{:fn, _, _}]}, _property, _caller) do
    raise "Dynamic functions are not supported. Callbacks should be remote functions in the &Mod.fun/arity format"
  end

  defp parse_property({:setter, _, [setter]}, property, _caller) do
    quote do
      unquote(property) = Builder.set_property_setter!(unquote(property), unquote(setter))
    end
  end

  defp parse_property({:annotation, _, [_ | _]} = annotation, property, caller) do
    process_annotation(annotation, property, caller)
  end

  defp parse_property(ast, _property, _caller) do
    ast
  end

  # Argument children parsing functions
  defp parse_argument({:annotation, _, [_ | _]} = annotation, argument, caller) do
    process_annotation(annotation, argument, caller)
  end

  defp parse_argument(ast, _argument, _caller) do
    ast
  end

  # defp process_annotation({:annotation, _meta, []}, _parent, _caller) do
  #   raise "Annotation definition requires 2 arguments"
  # end

  defp process_annotation({:annotation, _meta, [do: _block]}, _parent, _caller) do
    raise "Annotation definition does not support blocks"
  end

  defp process_annotation({:annotation, meta, [name]}, parent, caller) do
    IO.warn(
      "Annotation defined without a value. Implicit \"true\" has been set, but you should not rely on implicit values"
    )

    process_annotation({:annotation, meta, [name, true]}, parent, caller)
  end

  defp process_annotation({:annotation, _meta, [_, [do: _block]]}, _parent, _caller) do
    raise "Annotation definition does not support blocks"
  end

  defp process_annotation({:annotation, _meta, [name, value]}, parent, _caller) do
    quote do
      annotation = Builder.annotation!(unquote(name), unquote(value))

      if Builder.Finder.contains?(unquote(parent), annotation) do
        raise "Annotation \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(parent) = Builder.Insert.insert!(unquote(parent), annotation)
    end
  end

  defp process_annotation({:annotation, _meta, [_ | _]}, _member, _caller) do
    raise "Annotation number or type or arguments are not supported"
  end
end
