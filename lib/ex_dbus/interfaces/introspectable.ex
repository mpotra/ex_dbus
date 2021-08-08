defmodule ExDBus.Interfaces.Introspectable do
  use ExDBus.Schema
  alias ExDBus.Builder

  node do
    interface "org.freedesktop.DBus.Introspectable" do
      method "Introspect" do
        arg("xml_data", "s", :out)
        callback(&__MODULE__.introspect/1)
      end
    end
  end

  defp introspect({:object, _, _} = object) do
    root =
      Builder.root!()
      |> Builder.Insert.insert(object)

    xml_body = ExDBus.XML.to_xml(root)
    {:ok, [:string], [xml_body]}
  end

  defp introspect(_) do
    {:error, "org.freedesktop.DBus.Error.UnknownObject", "Object not valid"}
  end
end
