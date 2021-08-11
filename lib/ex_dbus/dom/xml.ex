defmodule ExDBus.XML.Saxy do
  use ExDBus.Spec, prefix: false
  import Saxy.XML

  @spec to_xml(definition(), keyword()) :: Saxy.XML.element()
  def to_xml(_, opts \\ [])

  def to_xml({:service, _, [root]}, opts) do
    to_xml(root, opts)
  end

  def to_xml({:annotation, name, value}, _opts) do
    element("annotation", [name: name, value: value], [])
  end

  def to_xml({:argument, name, type, direction, annotations}, opts) do
    attrs =
      if Keyword.get(opts, :attr_direction, true) == false do
        [name: name, type: type]
      else
        [name: name, type: type, direction: direction]
      end

    element("arg", attrs, xml_children(annotations, opts))
  end

  def to_xml({:property, name, type, access, annotations, _handle}, opts) do
    element("property", [name: name, type: type, access: access], xml_children(annotations, opts))
  end

  def to_xml({:method, name, children, _handle}, opts) do
    element("method", [name: name], xml_children(children, opts))
  end

  def to_xml({:signal, name, children}, opts) do
    opts = Keyword.put(opts, :attr_direction, false)
    element("signal", [name: name], xml_children(children, opts))
  end

  def to_xml({:interface, name, children}, opts) do
    element("interface", [name: name], xml_children(children, opts))
  end

  def to_xml({:object, "", children}, opts) do
    element("node", [], xml_children(children, opts))
  end

  def to_xml({:object, name, children}, opts) do
    element("node", [name: strip_absolute_path(name)], xml_children(children, opts))
  end

  defp xml_children([], _) do
    []
  end

  defp xml_children([child | children], opts) do
    [child_to_xml(child, opts) | xml_children(children, opts)]
  end

  defp child_to_xml({:object, name, _children} = child, opts) do
    if Keyword.get(opts, :nested_objects, true) == false do
      element("node", [name: strip_absolute_path(name)], [])
    else
      to_xml(child, opts)
    end
  end

  defp child_to_xml(child, opts) do
    to_xml(child, opts)
  end

  defp strip_absolute_path("/" <> name) do
    name
  end

  defp strip_absolute_path(name) do
    name
  end
end
