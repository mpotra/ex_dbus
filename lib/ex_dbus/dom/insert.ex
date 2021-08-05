defmodule ExDBus.Builder.Insert do
  use ExDBus.Spec, prefix: false
  alias ExDBus.Builder.Finder

  @spec insert!(service(), object()) :: service()
  @spec insert!(object(), object() | interface()) :: object()
  def insert!(parent, child) do
    case insert(parent, child) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @spec insert(service(), object()) :: {:ok, service()} | {:error, binary()}
  def insert({:service, _, []} = service, {:object, _, _} = object) do
    generic_insert(service, object)
  end

  def insert({:service, name, [{:object, node_name, _} | _]}, _) do
    raise "Service #{name} already has a root node (#{node_name}) set"
  end

  @spec insert(object(), object() | interface()) :: {:ok, object()} | {:error, binary()}
  def insert({:object, _, _} = object, {:object, _, _} = child) do
    generic_insert(object, child)
  end

  def insert({:object, _, _} = object, {:interface, _, _} = interface) do
    generic_insert(object, interface)
  end

  def insert({:interface, _, _} = interface, {:annotation, _, _} = annotation) do
    generic_insert(interface, annotation)
  end

  def insert({:interface, _, _} = interface, {:signal, _, _} = signal) do
    generic_insert(interface, signal)
  end

  def insert({:interface, _, _} = interface, {:method, _, _, _} = method) do
    insert_method(interface, method)
  end

  def insert({:interface, _, _} = interface, {:property, _, _, _, _, _} = property) do
    generic_insert(interface, property)
  end

  def insert({:method, _, _, _} = method, {:annotation, _, _} = annotation) do
    method_insert_child(method, annotation)
  end

  def insert({:method, _, _, _} = method, {:argument, _, _, _, _} = argument) do
    method_insert_child(method, argument)
  end

  def insert({:signal, _, _} = signal, {:annotation, _, _} = annotation) do
    generic_insert(signal, annotation)
  end

  def insert({:signal, _, _} = signal, {:argument, _, _, _, _} = argument) do
    generic_insert(signal, argument)
  end

  def insert(
        {:property = tag, name, type, access, annotations, handle} = property,
        {:annotation, _, _} = annotation
      ) do
    if can_insert?(property, annotation, &Finder.find_index/2) do
      {:ok, {tag, name, type, access, [annotation | annotations], handle}}
    else
      {:error, "Annotation already exists in :#{tag} named #{name}"}
    end
  end

  def insert(
        {:argument = tag, name, type, direction, annotations} = argument,
        {:annotation, _, _} = annotation
      ) do
    if can_insert?(argument, annotation, &Finder.find_index/2) do
      {:ok, {tag, name, type, direction, [annotation | annotations]}}
    else
      {:error, "Annotation already exists in :#{tag} named #{name}"}
    end
  end

  # Private methods
  defp can_insert?(parent, child, fn_find) do
    parent
    |> fn_find.(child)
    |> case do
      {-1, _} -> true
      {_index, _existing} -> false
    end
  end

  defp generic_insert({tag, name, children} = parent, child) do
    if can_insert?(parent, child, &Finder.find_index/2) do
      {:ok, {tag, name, [child | children]}}
    else
      {:error, "Child already exists in parent :#{tag} named #{name}"}
    end
  end

  defp insert_method({tag, name, members} = interface, method) do
    if can_insert?(interface, method, &Finder.find_method_index/2) do
      {:ok, {tag, name, [method | members]}}
    else
      {:error, "Method with name and arguments already exists in parent :#{tag} named #{name}"}
    end
  end

  defp method_insert_child(
         {tag, name, children, handle} = method,
         {:annotation, _, _} = annotation
       ) do
    if can_insert?(method, annotation, &Finder.find_index/2) do
      {:ok, {tag, name, [annotation | children], handle}}
    else
      {:error, "Annotation already exists in :#{tag} named #{name}"}
    end
  end

  defp method_insert_child(
         {tag, name, children, handle},
         {:argument, _, _, _, _} = argument
       ) do
    {:ok, {tag, name, [argument | children], handle}}
  end
end
