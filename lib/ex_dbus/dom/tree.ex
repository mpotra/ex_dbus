defmodule ExDBus.Tree do
  use ExDBus.Spec, prefix: false
  alias ExDBus.Builder

  @type find_result(v) :: {:ok, v} | :error

  @spec get_tag(definition() | service() | any()) :: tag() | nil
  def get_tag({:object, _, _}), do: :object
  def get_tag({:interface, _, _}), do: :interface
  def get_tag({:method, _, _, _}), do: :method
  def get_tag({:signal, _, _}), do: :signal
  def get_tag({:property, _, _, _, _, _}), do: :property
  def get_tag({:annotation, _, _}), do: :annotation
  def get_tag({:argument, _, _, _, _}), do: :argument
  def get_tag({:service, _, _}), do: :service
  def get_tag(_), do: nil

  # Object functions

  @spec match_path?(node :: object(), name :: binary()) :: boolean()
  def match_path?({:object, "", _}, "/") do
    true
  end

  def match_path?({:object, "/", _}, "") do
    true
  end

  def match_path?({:object, path, _}, path) do
    true
  end

  def match_path?(_, _) do
    false
  end

  @spec find_child_object(object(), list(binary())) :: {:ok, object()} | :error
  def find_child_object({:object, _, []}, _) do
    :error
  end

  def find_child_object({:object, _name, children}, path) when is_binary(path) do
    paths =
      path
      |> split_path()
      |> Enum.reject(&(&1 == "/"))

    find_object(children, paths)
  end

  def find_child_object({:object, _, _}, []) do
    :error
  end

  def find_child_object({:object, _, _}, [""]) do
    :error
  end

  def find_child_object({:object, _, _}, ["/"]) do
    :error
  end

  def find_child_object({:object, _, children}, [name]) do
    find_object(children, name)
  end

  def find_child_object({:object, _, _} = parent, [name | paths] = path) do
    with {:ok, child} <- find_child_object(parent, join_path(path)) do
      {:ok, child}
    else
      _ ->
        case find_child_object(parent, name) do
          {:ok, child} -> find_child_object(child, paths)
          :error -> :error
        end
    end
  end

  @doc """
  Find an object matching given path, within a list of objects
  """
  @spec find_object(list(), path :: binary() | list(binary())) :: {:ok, object()} | :error
  def find_object([], _) do
    :error
  end

  def find_object([{:object, _, _} = head | tail], name) when is_binary(name) do
    if match_path?(head, name) do
      {:ok, head}
    else
      find_object(tail, name)
    end
  end

  def find_object([_ | tail], name) when is_binary(name) do
    find_object(tail, name)
  end

  def find_object(objects, []) when is_list(objects) do
    :error
  end

  def find_object(objects, [name]) when is_list(objects) do
    find_object(objects, name)
  end

  def find_object(objects, [name | tail] = path) when is_list(objects) do
    with {:ok, object} <- find_object(objects, join_path(path)) do
      {:ok, object}
    else
      _ ->
        case find_object(objects, name) do
          {:ok, object} ->
            find_child_object(object, tail)

          :error ->
            :error
        end
    end
  end

  def find_object([_ | tail], path) when is_list(path) do
    find_object(tail, path)
  end

  @spec find_path(object() | list(object()), binary()) :: find_result(object())
  def find_path(objects, "/") when is_list(objects) do
    find_object(objects, "/")
  end

  def find_path(objects, path) when is_list(objects) and is_binary(path) do
    find_object(objects, split_path(path))
  end

  def find_path({:object, _, _} = object, path) do
    find_path([object], path)
  end

  @spec find_path!(object() | list(object()), binary()) :: object()
  def find_path!(source, path) do
    case find_path(source, path) do
      :error -> raise RuntimeError, "Path [#{path}] not found"
      {:ok, result} -> result
    end
  end

  # Children getter

  @spec children(
          element(),
          :any | tag() | list(tag())
        ) :: list()
  def children(_, filter \\ :any)

  def children({:object, _, []}, _) do
    []
  end

  def children({:object, _, children}, :any) do
    children
  end

  def children({:object, _, children}, types) when is_atom(types) or is_list(types) do
    filter(children, types)
  end

  def children({:interface, _, []}, _) do
    []
  end

  def children({:interface, _, children}, :any) do
    children
  end

  def children({:interface, _, children}, types) when is_atom(types) or is_list(types) do
    filter(children, types)
  end

  # Filter lists of definitions
  @spec filter(list(definition()), atom() | list(atom())) :: list(definition())
  def filter([], _) do
    []
  end

  def filter(list, type) when is_list(list) and is_atom(type) do
    filter(list, [type])
  end

  def filter(_list, []) do
    []
  end

  def filter([head | tail], types) when is_list(types) do
    if Enum.member?(types, get_tag(head)) do
      [head | filter(tail, types)]
    else
      filter(tail, types)
    end
  end

  # Interface functions
  @spec find_interface(object(), binary()) :: find_result(interface())
  def find_interface({:object, _, []}, _) do
    :error
  end

  def find_interface({:object, _, ""}, "") do
    :error
  end

  def find_interface({:object, _, children}, name) when is_binary(name) do
    find_interface(children, name)
  end

  @spec find_interface(list(object() | interface()), binary()) :: find_result(interface())
  def find_interface([], _) do
    :error
  end

  def find_interface([{:interface, name, _} = interface | _], name) when is_binary(name) do
    {:ok, interface}
  end

  def find_interface([_ | tail], name) when is_binary(name) do
    find_interface(tail, name)
  end

  @spec find_interface!(object(), binary()) :: interface()
  def find_interface!({:object, _, _} = object, name) do
    case find_interface(object, name) do
      {:ok, interface} -> interface
      _ -> raise "Interface #{name} not found in object"
    end
  end

  def find_interface!(_, _) do
    raise "Cannot find interface outside of :object node"
  end

  @spec replace_interface(object(), interface()) :: {:ok, object()} | :error
  def replace_interface({:object, _, _} = object, {:interface, name, _} = interface) do
    replace_interface(object, name, interface)
  end

  @spec replace_interface(object(), String.t(), interface()) :: {:ok, object()} | :error
  def replace_interface(
        {:object, object_name, children} = object,
        interface_name,
        {:interface, _, _} = interface
      )
      when is_binary(interface_name) do
    case Builder.Finder.find_index(object, {:interface, interface_name, []}) do
      {-1, _} ->
        :error

      {index, _} ->
        children = List.replace_at(children, index, interface)
        {:object, object_name, children}
    end
  end

  @spec replace_interface_at(object(), String.t() | list(), interface()) ::
          {:ok, object()} | :error
  def replace_interface_at(object, path, interface) when is_list(path) do
    replace_interface_at(object, join_path(path), interface)
  end

  def replace_interface_at(
        {:object, _object_name, _children} = object,
        search_path,
        {:interface, interface_name, _} = replace_interface
      )
      when is_binary(search_path) do
    {object, result} =
      ExDBus.Tree.Traverse.traverse(
        object,
        {false, nil, []},
        fn
          child, {true, _, _} = acc ->
            {child, acc}

          {:object, name, _} = child, {_, _, paths} = _acc ->
            {child, {false, nil, [name | paths]}}

          {:interface, name, _} = interface, {false, nil, paths} = acc ->
            path = join_path(Enum.reverse(paths))

            if path == search_path and name == interface_name do
              {replace_interface, {true, interface, paths}}
            else
              {interface, acc}
            end

          child, acc ->
            {child, acc}
        end,
        fn
          child, {true, _, _} = acc ->
            {child, acc}

          {:object, _, _} = child, {_, _, paths} = _acc ->
            [_ | paths] = paths
            {child, {false, nil, paths}}

          child, acc ->
            {child, acc}
        end
      )

    case result do
      {true, _old_interface, _} -> {:ok, object}
      {false, _, _} -> :error
    end
  end

  # Method functions
  def find_method(nil, _, _) do
    :error
  end

  def find_method(_, nil, _) do
    :error
  end

  def find_method(interface, method, signature) do
    Builder.Finder.find_method(interface, method, signature)
  end

  @spec get_method_callback(method()) :: :error | nil | {:ok, method_handle()}
  def get_method_callback({:method, _, _, callback}) when is_function(callback) do
    {:ok, callback}
  end

  def get_method_callback({:method, _, _, {:call, _, _} = callback}) do
    {:ok, callback}
  end

  def get_method_callback({:method, _, _, nil}) do
    nil
  end

  def get_method_callback(_) do
    :error
  end

  @spec set_method_callback(method(), method_handle()) :: nil | method()
  def set_method_callback({:method, name, children, _}, callback) do
    {:method, name, children, callback}
  end

  def set_method_callback(_, _) do
    nil
  end

  # Property function
  @spec find_property(interface(), String.t()) :: find_result(property())
  def find_property({:interface, _, _} = interface, property_name) do
    Builder.Finder.find(interface, {:property, property_name, nil, :readwrite, [], nil})
  end

  def get_properties({:interface, _, members}) do
    filter(members, :property)
  end

  def property_name({:property, name, _, _, _, _}) do
    name
  end

  def property_type({:property, _, type, _, _, _}) do
    type
  end

  def property_access({:property, _, _, access, _, _}) do
    access
  end

  @spec property_getter(property()) :: property_getter()
  def property_getter({:property, _, _, _, _, {getter, _}}) do
    getter
  end

  @spec property_setter(property()) :: property_setter()
  def property_setter({:property, _, _, _, _, {_, setter}}) do
    setter
  end

  def set_property_getter({:property, name, type, access, annotations, {_, setter}}, getter) do
    {:property, name, type, access, annotations, {getter, setter}}
  end

  def set_property_setter({:property, name, type, access, annotations, {getter, _}}, setter) do
    {:property, name, type, access, annotations, {getter, setter}}
  end

  defp split_path(path) when is_binary(path) do
    path
    |> String.split("/")
    |> Enum.map(&("/" <> &1))
  end

  defp join_path([]) do
    "/"
  end

  defp join_path([path]) do
    path
  end

  defp join_path(["/" | tail]) do
    join_path(tail)
  end

  defp join_path([_ | _] = paths) do
    Enum.join(paths, "")
  end
end
