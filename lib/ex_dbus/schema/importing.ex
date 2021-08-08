defmodule ExDBus.Schema.Importing do
  @moduledoc """


  Importing other schemas:

  - Importing interfaces.
  Inside a <node> definition, it is possible to import
  nodes and interfaces from other schemas, using the `import from()` syntax:

  1. Importing all root node children of nodes and interfaces from another schema
  `import from(Module)` - alias of `import from(Module), path: "/"`
  2. Importing all nodes and interfaces under a given path, from another Schema:
  `import from(Module), path: "/"` - imports all under the root node.
  `import from(Module), path: "/Child"` - imports from Module schema,
    all nodes and interfaces inside the node named `/Child` that is a
    a child of the root node.
  `import from(Module), path: "/Child/Level2Child"` - imports from Module schema,
    all nodes and interfaces inside the node named `/Level2Child`
    root (/)
      -- Child
        -- Level2Child
          -- (nodes and interfaces that are imported)
  3. Importing specific interfaces and nodes from a given Module schema:

  Imports the `org.example.InterfaceName` defined in the root (`/`) node of
  Module schema.
  ```
  import from(Module) do
    interface("org.example.InterfaceName")
  end
  ```

  Imports the `org.example.InterfaceName` defined in the node named `/Child`
  of the Module schema.
  ```
  import from(Module) do
    interface("org.example.InterfaceName"), path: "/Child"
  end
  ```
  can also be written as
  ```
  import from(Module), path: "/Child" do
    interface("org.example.InterfaceName")
  end
  ```

  4. Import aliasing
  An import can be aliased - available only in the block syntax.
  ```
  import from(Module) do
    interface("org.example.InterfaceName"), as: "org.example.RenamedInterface"
  end
  ```

  CAVEAT:
  Importing requires interfaces to define the following with public functions:
  - method `callback()`
  - property `setter()` and property `getter()`

  Using private functions in a schema that is to be imported,
  will fail in the importing schema.

  TODO: Implement references, to preserve private functions
  {:reference, name, {schema, path, {:object, object_name}}}
  {:reference, name, {schema, path, {:interface, interface_name}}}
  """
  alias ExDBus.Builder

  def parse_node({:import, _meta, [[do: _block]]} = ast, _caller) do
    ast
  end

  def parse_node({:import, _meta, [{:from, _from_meta, [source]}]}, caller) do
    import_from_source(source, "/", caller)
  end

  def parse_node(
        {:import, _meta,
         [
           {:from, _from_meta, [source]},
           [path: path]
         ]},
        caller
      ) do
    import_from_source(source, path, caller)
  end

  def parse_node(
        {:import, _meta,
         [
           {:from, _from_meta, [source]},
           [path: path],
           [do: block]
         ]},
        caller
      ) do
    source = get_expanded_source(source, caller)
    node = get_source_path_node(source, path, caller)

    Macro.prewalk(block, &parse_node_import(&1, {source, node}, caller))
  end

  def parse_node(
        {:import, _meta,
         [
           {:from, _from_meta, [source]},
           [do: block]
         ]},
        caller
      ) do
    source = get_expanded_source(source, caller)
    node = get_source_path_node(source, "/", caller)

    Macro.prewalk(block, &parse_node_import(&1, {source, node}, caller))
  end

  # def parse_node({:import, _meta, b}, _caller) do
  #   IO.inspect(b, label: "IMPORT FROM OTHER")
  #   :ok
  # end

  def parse_node({:import, _, _} = node, _caller) do
    node
  end

  defp parse_node_import({:interface, [_ | _] = _meta, [name]}, {_source, node}, caller) do
    import_interface_from_source(node, "/", name, name, caller)
  end

  defp parse_node_import(
         {:interface, [_ | _] = _meta, [name, opts]} = ast,
         {_source, node},
         caller
       ) do
    if Keyword.keyword?(opts) do
      path = Keyword.get(opts, :path, "/")
      as_name = Keyword.get(opts, :as, name)

      opts
      |> Keyword.drop([:path, :as])
      |> case do
        [] -> :ok
        keys -> raise "Unknown options #{keys} given to interface(name)"
      end

      import_interface_from_source(node, path, name, as_name, caller)
    else
      ast
    end
  end

  defp parse_node_import({:interface, _, _} = ast, {_source, _node}, _caller) do
    ast
  end

  defp parse_node_import(ast, _, _) do
    ast
  end

  defp import_interface_from_source(node, path, find_name, as_name, caller) do
    node
    |> ExDBus.Tree.find_path!(path)
    |> ExDBus.Tree.find_interface(find_name)
    |> case do
      {:ok, {:interface, _, children}} -> [{:interface, as_name, children}]
      _ -> []
    end
    |> build_import_block(caller)
  end

  defp import_from_source(source, path, caller) do
    source
    |> get_source_path_node(path, caller)
    |> ExDBus.Tree.children()
    |> build_import_block(caller)
  end

  defp get_expanded_source({:__aliases__, _, _} = source, caller) do
    Macro.expand(source, caller)
  end

  defp get_expanded_source(source, _caller) when is_atom(source) do
    source
  end

  defp get_source_path_node(source, path, caller) do
    source_module = get_expanded_source(source, caller)

    source_root =
      try do
        source_module.__schema__()
      rescue
        e in UndefinedFunctionError -> raise e
      end

    ExDBus.Tree.find_path!(source_root, path)
  end

  defp build_import_block(children, _caller) do
    object = Macro.var(:object, ExDBus.Schema)

    block =
      children
      |> Enum.map(fn child ->
        child = Macro.escape(child)

        quote do
          unquote(object) = Builder.Insert.insert!(unquote(object), unquote(child))
        end
      end)

    {:__block__, [], block}
  end
end
