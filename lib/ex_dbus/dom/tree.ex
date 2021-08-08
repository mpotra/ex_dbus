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

  def find_child_object({:object, _, children}, path) when is_binary(path) do
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

  def find_child_object({:object, _, _} = parent, [name, paths]) do
    case find_child_object(parent, name) do
      {:ok, child} -> find_child_object(child, paths)
      :error -> :error
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

  def find_object(objects, [name | tail]) when is_list(objects) do
    case find_object(objects, name) do
      {:ok, object} -> find_child_object(object, tail)
      :error -> :error
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

  # Method functions
  def find_method(_, _, _) do
    :error
  end

  defp split_path(path) when is_binary(path) do
    path
    |> String.split("/")
    |> Enum.map(&("/" <> &1))
  end
end
