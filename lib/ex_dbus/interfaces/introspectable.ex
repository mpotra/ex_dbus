defmodule ExDBus.Interfaces.Introspectable do
  use ExDBus.Schema

  node do
    interface "org.freedesktop.DBus.Introspectable" do
      method "Introspect" do
        arg("xml_data", "s", :out)
        callback(&__MODULE__.introspect/2)
      end
    end
  end

  def introspect(_, %{path: "/", node: {:object, _, children}}) do
    children =
      children
      |> Enum.filter(&(elem(&1, 0) == :object))
      |> Enum.map(fn {:object, name, _} -> {:object, name, []} end)

    root = {:object, "", children}
    xml_body = ExDBus.XML.to_xml(root, nested_objects: false)
    {:ok, [:string], [xml_body]}
  end

  def introspect(_, %{node: {:object, _, children}}) do
    root = {:object, "", children}
    xml_body = ExDBus.XML.to_xml(root)
    {:ok, [:string], [xml_body]}
  end

  def introspect(_, _) do
    {:error, "org.freedesktop.DBus.Error.UnknownObject", "Object not valid"}
  end
end
