defmodule ExDBus.Builder.Reverse do
  use ExDBus.Spec, prefix: false

  @spec reverse(service()) :: service()
  def reverse({:service, name, children}) do
    {:service, name, Enum.reverse(children)}
  end

  @spec reverse(object()) :: object()
  def reverse({:object, name, children}) do
    {:object, name, Enum.reverse(children)}
  end

  @spec reverse(interface()) :: interface()
  def reverse({:interface, name, members}) do
    {:interface, name, Enum.reverse(members)}
  end

  @spec reverse(method()) :: method()
  def reverse({:method, name, children, handle}) do
    {:method, name, Enum.reverse(children), handle}
  end

  @spec reverse(signal()) :: signal()
  def reverse({:signal, name, children}) do
    {:signal, name, Enum.reverse(children)}
  end

  @spec reverse(argument()) :: argument()
  def reverse({:argument, name, type, direction, annotations}) do
    {:argument, name, type, direction, Enum.reverse(annotations)}
  end

  @spec reverse(property()) :: property()
  def reverse({:property, name, type, access, annotations, handle}) do
    {:property, name, type, access, Enum.reverse(annotations), handle}
  end

  # Not really useful, but here for consistency.
  @spec reverse(annotation()) :: annotation()
  def reverse({:annotation, _, _} = annotation) do
    annotation
  end
end
