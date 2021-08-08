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
    block = Macro.prewalk(block, &parse_node(&1, caller))

    node_block =
      quote do
        object = Builder.root!(unquote(name))
        unquote(block)
        object = Builder.Reverse.reverse(object)
        Module.put_attribute(__MODULE__, :__schema_root__, object)
      end

    node_block
  end

  defp parse_node({:interface, _meta, [name, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_interface(&1, caller))

    quote do
      interface = Builder.interface!(unquote(name))

      if Builder.Finder.contains?(object, interface) do
        raise "Interface \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(block)

      interface = Builder.Reverse.reverse(interface)

      object = Builder.Insert.insert!(object, interface)
    end
  end

  defp parse_node({:node, _meta, [name]}, _caller) do
    quote do
      parent_object = object
      object = Builder.object!(unquote(name))

      if Builder.Finder.contains?(parent_object, object) do
        raise "Object \"#{unquote(name)}\" already defined in parent node"
      end

      object = Builder.Insert.insert!(parent_object, object)
    end
  end

  defp parse_node({:node, _meta, [name, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_node(&1, caller))

    quote do
      parent_object = object
      object = Builder.object!(unquote(name))

      if Builder.Finder.contains?(parent_object, object) do
        raise "Object \"#{unquote(name)}\" already defined in parent node"
      end

      unquote(block)

      object = Builder.Reverse.reverse(object)

      object = Builder.Insert.insert!(parent_object, object)
    end
  end

  defp parse_node({:import, _, _} = ast, caller) do
    Importing.parse_node(ast, caller)
  end

  defp parse_node(ast, _caller) do
    ast
  end

  defp parse_interface({:interface, _meta, [_ | _]}, _) do
    raise "Cannot define interface in another interface"
  end

  defp parse_interface({:node, _meta, [_ | _]}, _) do
    raise "Cannot define node inside an interface"
  end

  defp parse_interface({:annotation, _, [_ | _]} = annotation, caller) do
    block = process_annotation(annotation, caller)

    quote do
      parent = interface
      unquote(block)
      interface = parent
    end
  end

  defp parse_interface({:method, _, [name, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_method(&1, caller))

    quote do
      method = Builder.method!(unquote(name))

      parent = method
      unquote(block)
      method = Builder.Reverse.reverse(parent)

      # if Builder.Finder.contains?(interface, method) do
      #   raise "Method \"#{unquote(name)}\" already defined in parent node"
      # end

      interface = Builder.Insert.insert!(interface, method)
    end
  end

  defp parse_interface({:method, _, [[do: _block]]}, _) do
    raise "Method definition requires a name argument"
  end

  defp parse_interface({:method, _, [_]}, _) do
    raise "Method definition requires a block"
  end

  defp parse_interface({:method, _, [_ | _]}, _) do
    raise "Method definition unsupported"
  end

  defp parse_interface({:signal, _, [name, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_signal(&1, caller))

    quote do
      signal = Builder.signal!(unquote(name))

      if Builder.Finder.contains?(interface, signal) do
        raise "Signal \"#{unquote(name)}\" already defined in interface"
      end

      parent = signal
      unquote(block)
      signal = Builder.Reverse.reverse(parent)

      interface = Builder.Insert.insert!(interface, signal)
    end
  end

  defp parse_interface({:signal, _, [name]}, _caller) do
    quote do
      signal = Builder.signal!(unquote(name))

      if Builder.Finder.contains?(interface, signal) do
        raise "Signal \"#{unquote(name)}\" already defined in interface"
      end

      interface = Builder.Insert.insert!(interface, signal)
    end
  end

  defp parse_interface({:signal, _, [_ | _]}, _) do
    raise "Signal definition requires name and optional block"
  end

  defp parse_interface({:property, _, [name, type, access, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_property(&1, caller))

    quote do
      property = Builder.property!(unquote(name), unquote(type), unquote(access))

      if Builder.Finder.contains?(interface, property) do
        raise "Property \"#{unquote(name)}\" already defined in interface"
      end

      parent = property
      unquote(block)
      property = Builder.Reverse.reverse(parent)
      interface = Builder.Insert.insert!(interface, property)
    end
  end

  defp parse_interface({:property, _, [name, type, access]}, _caller) do
    quote do
      property = Builder.property!(unquote(name), unquote(type), unquote(access))

      if Builder.Finder.contains?(interface, property) do
        raise "Property \"#{unquote(name)}\" already defined in interface"
      end

      interface = Builder.Insert.insert!(interface, property)
    end
  end

  defp parse_interface({:property, _, [_ | _]}, _) do
    raise "Property definition requires 3 arguments and optional block"
  end

  defp parse_interface(ast, _caller) do
    ast
  end

  # Signal children parsing functions

  defp parse_signal({:arg, meta, [name, type]}, caller) do
    parse_signal({:arg, meta, [name, type, :out]}, caller)
  end

  defp parse_signal({:arg, _, [name, type, :out]}, _caller) do
    quote do
      argument = Builder.argument!(unquote(name), unquote(type), :out)
      parent = Builder.Insert.insert!(parent, argument)
    end
  end

  defp parse_signal({:arg, meta, [name, type, [do: block]]}, caller) do
    parse_signal({:arg, meta, [name, type, :out, [do: block]]}, caller)
  end

  defp parse_signal({:arg, _, [name, type, :out, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_argument(&1, caller))

    quote do
      argument = Builder.argument!(unquote(name), unquote(type), :out)
      prev_parent = parent
      parent = argument
      unquote(block)
      argument = Builder.Reverse.reverse(parent)
      parent = Builder.Insert.insert!(prev_parent, argument)
    end
  end

  defp parse_signal({:arg, _, [_ | _]}, _) do
    raise "Signal argument definition requires 2 arguments, optional :out direction and optional block"
  end

  defp parse_signal({:annotation, _, [_ | _]} = annotation, caller) do
    process_annotation(annotation, caller)
  end

  defp parse_signal(ast, _) do
    ast
  end

  # Method children parsing functions

  defp parse_method({:arg, _, [name, type, direction]}, _caller) do
    quote do
      argument = Builder.argument!(unquote(name), unquote(type), unquote(direction))
      parent = Builder.Insert.insert!(parent, argument)
    end
  end

  defp parse_method({:arg, _, [name, type, direction, [do: block]]}, caller) do
    block = Macro.prewalk(block, &parse_argument(&1, caller))

    quote do
      argument = Builder.argument!(unquote(name), unquote(type), unquote(direction))
      prev_parent = parent
      parent = argument
      unquote(block)
      argument = Builder.Reverse.reverse(parent)
      parent = Builder.Insert.insert!(prev_parent, argument)
    end
  end

  defp parse_method({:arg, _, [_ | _]}, _) do
    raise "Method argument definition requires 3 arguments and optional block"
  end

  defp parse_method({:callback, _, [callback]}, _) do
    quote do
      parent = Builder.set_method_callback!(parent, unquote(callback))
    end
  end

  defp parse_method({:annotation, _, [_ | _]} = annotation, caller) do
    process_annotation(annotation, caller)
  end

  defp parse_method(ast, _) do
    ast
  end

  # Property parsing functions
  defp parse_property({:getter, _, [getter]}, _) do
    quote do
      parent = Builder.set_property_getter!(parent, unquote(getter))
    end
  end

  defp parse_property({:setter, _, [setter]}, _) do
    quote do
      parent = Builder.set_property_setter!(parent, unquote(setter))
    end
  end

  defp parse_property({:annotation, _, [_ | _]} = annotation, caller) do
    process_annotation(annotation, caller)
  end

  defp parse_property(ast, _) do
    ast
  end

  # Argument children parsing functions
  defp parse_argument({:annotation, _, [_ | _]} = annotation, caller) do
    process_annotation(annotation, caller)
  end

  defp parse_argument(ast, _) do
    ast
  end

  defp process_annotation({:annotation, _meta, []}, _caller) do
    raise "Annotation definition requires 2 arguments"
  end

  defp process_annotation({:annotation, _meta, [do: _block]}, _) do
    raise "Annotation definition does not support blocks"
  end

  defp process_annotation({:annotation, meta, [name]}, caller) do
    IO.warn(
      "Annotation defined without a value. Implicit \"true\" has been set, but you should not rely on implicit values"
    )

    process_annotation({:annotation, meta, [name, true]}, caller)
  end

  defp process_annotation({:annotation, _meta, [_, [do: _block]]}, _) do
    raise "Annotation definition does not support blocks"
  end

  defp process_annotation({:annotation, _meta, [name, value]}, _caller) do
    quote do
      annotation = Builder.annotation!(unquote(name), unquote(value))

      if Builder.Finder.contains?(parent, annotation) do
        raise "Annotation \"#{unquote(name)}\" already defined in parent node"
      end

      parent = Builder.Insert.insert!(parent, annotation)
    end
  end

  defp process_annotation({:annotation, _meta, [_ | _]}, _caller) do
    raise "Annotation number or type or arguments are not supported"
  end
end
