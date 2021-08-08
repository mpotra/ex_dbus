defmodule ExDBus.Builder.Finder do
  use ExDBus.Spec, prefix: false

  @spec find_index(service(), name() | object()) :: {index(), object() | nil}
  def find_index({:service, _, children}, name) when is_binary(name) do
    find_by_name(children, name)
  end

  def find_index({:service, _, _} = service, {:object, name, _}) do
    find_index(service, name)
  end

  @spec find_index(object(), name() | object() | interface()) ::
          {index(), object() | interface() | nil}
  def find_index({:object, _name, children}, name) when is_binary(name) do
    find_by_name(children, name)
  end

  def find_index({:object, _name, children}, {:object, name, _children}) do
    find_by_name(children, name)
  end

  def find_index({:object, _name, children}, {:interface, name, _children}) do
    find_by_name(children, name)
  end

  @spec find_index(interface(), name() | object() | member()) ::
          {index(), object() | member() | nil}
  def find_index({:interface, _name, children}, {:object, name, _children}) do
    find_by_name(children, name)
  end

  def find_index({:interface, _name, children}, {:annotation, name, _value}) do
    find_by_name(children, name)
  end

  def find_index({:interface, _name, children}, {:signal, name, _children}) do
    find_by_name(children, name)
  end

  def find_index(
        {:interface, _name, children},
        {:property, name, _type, _access, _annotations, _handle}
      ) do
    find_by_name(children, name)
  end

  def find_index(
        {:interface, _name, children},
        {:method, _method_name, _children, _handle} = method
      ) do
    find_method(children, method)
  end

  @spec find_index(member(), argument() | annotation()) ::
          {index(), argument() | annotation() | nil}
  def find_index(
        {:method, _, children, _handle},
        {:argument, name, _type, _direction, _annotations}
      ) do
    find_by_name(children, name)
  end

  def find_index({:method, _name, children, _handle}, {:annotation, name, _value}) do
    find_by_name(children, name)
  end

  def find_index({:signal, _name, children}, {:argument, name, _type, _direction, _annotations}) do
    find_by_name(children, name)
  end

  def find_index({:signal, _name, children}, {:annotation, name, _value}) do
    find_by_name(children, name)
  end

  def find_index(
        {:property, _name, _type, _access, annotations, _handle},
        {:annotation, name, _value}
      ) do
    find_by_name(annotations, name)
  end

  @spec find_index(argument(), annotation()) :: {index(), annotation()}
  def find_index({:argument, _name, _type, _direction, annotations}, {:annotation, name, _value}) do
    find_by_name(annotations, name)
  end

  @spec find(service(), name() | object()) :: {:ok, object()} | :error
  @spec find(object(), name() | object() | interface()) ::
          {:ok, object() | interface()} | :error
  @spec find(interface(), name() | object() | member()) ::
          {:ok, object() | member()} | :error
  @spec find(member(), argument() | annotation()) ::
          {:ok, argument() | annotation()} | :error
  @spec find(argument(), annotation()) :: {:ok, annotation()} | :error
  def find(parent, search) do
    case find_index(parent, search) do
      {-1, _} -> :error
      {_, child} -> {:ok, child}
    end
  end

  @spec contains?(service(), name() | object()) :: boolean()
  @spec contains?(object(), name() | object() | interface()) :: boolean()
  @spec contains?(interface(), name() | object() | member()) :: boolean()
  @spec contains?(member(), argument() | annotation()) :: boolean()
  @spec contains?(argument(), annotation()) :: boolean()
  def contains?(parent, search) do
    case find_index(parent, search) do
      {-1, _} -> false
      _ -> true
    end
  end

  @doc """
  Find all method nodes inside an interface that match the given name.
  Useful to retrieve a list of all method signatures.
  """

  @spec find_methods_index(interface(), method() | String.t()) :: list({index, method()})
  def find_methods_index({:interface, _name, children}, name) when is_binary(name) do
    find_interface_methods(children, name, 0)
  end

  def find_methods_index({:interface, _, _} = interface, {:method, name, _children, _handle}) do
    find_methods_index(interface, name)
  end

  @spec find_methods(interface(), method() | String.t()) :: list(method())
  def find_methods(interface, search) do
    interface
    |> find_methods_index(search)
    |> Enum.map(fn {_, method} -> method end)
  end

  @spec find_method_index(interface(), method()) :: {index(), method() | nil}
  def find_method_index({:interface, _name, children}, {:method, name, method_children, _handle}) do
    find_interface_method(children, name, filter_arguments(method_children), 0)
  end

  @spec find_method(interface(), method()) :: method() | nil
  def find_method(interface, method) do
    {_, method} = find_method_index(interface, method)

    method
  end

  ### Private functions

  defp find_by_name(_, _, index \\ 0)

  defp find_by_name([], _, _) do
    {-1, nil}
  end

  defp find_by_name([{:object, name, _children} = child | _], name, index) do
    {index, child}
  end

  defp find_by_name([{:interface, name, _children} = child | _], name, index) do
    {index, child}
  end

  defp find_by_name([{:signal, name, _children} = child | _], name, index) do
    {index, child}
  end

  defp find_by_name(
         [{:property, name, _type, _access, _annotations, _handle} = child | _],
         name,
         index
       ) do
    {index, child}
  end

  defp find_by_name([{:argument, name, _type, _direction, _annotations} = child | _], name, index) do
    {index, child}
  end

  defp find_by_name([{:annotation, name, _value} = child | _], name, index) do
    {index, child}
  end

  defp find_by_name([_ | children], name, index) do
    find_by_name(children, name, index + 1)
  end

  defp find_interface_methods([], _name, _index) do
    []
  end

  defp find_interface_methods(
         [{:method, name, _children, _handle} = method | methods],
         name,
         index
       ) do
    [{index, method} | find_interface_methods(methods, name, index + 1)]
  end

  defp find_interface_methods([_ | methods], name, index) do
    find_interface_methods(methods, name, index + 1)
  end

  defp filter_arguments([]) do
    []
  end

  defp filter_arguments([
         {:argument, _name, _type, _direction, _annotations} = argument | children
       ]) do
    [argument | filter_arguments(children)]
  end

  defp filter_arguments([_ | children]) do
    filter_arguments(children)
  end

  defp method_signature_match?(
         [
           {:argument, _name1, type, direction, _annotations1} | args1
         ],
         [
           {:argument, _name2, type, direction, _annotations2} | args2
         ]
       ) do
    method_signature_match?(args1, args2)
  end

  defp method_signature_match?([], []) do
    true
  end

  defp method_signature_match?(_, _) do
    false
  end

  defp find_interface_method([], _name, _arguments, _index) do
    {-1, nil}
  end

  defp find_interface_method(
         [{:method, name, children, _handle} = method | methods],
         name,
         arguments,
         index
       ) do
    if method_signature_match?(filter_arguments(children), arguments) do
      {index, method}
    else
      find_interface_method(methods, name, arguments, index + 1)
    end
  end

  defp find_interface_method([_ | methods], name, arguments, index) do
    find_interface_method(methods, name, arguments, index + 1)
  end
end
