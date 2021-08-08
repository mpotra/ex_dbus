defmodule ExDBus.Interfaces.Properties do
  use ExDBus.Schema

  node do
    interface "org.freedesktop.DBus.Properties" do
      method "Get" do
        arg("interface_name", "s", :in)
        arg("property_name", "s", :in)
        arg("value", "v", :out)
      end

      method "GetAll" do
        arg("interface_name", "s", :in)
        arg("properties", "a{sv}", :out)
      end

      method "Set" do
        arg("interface_name", "s", :in)
        arg("property_name", "s", :in)
        arg("value", "v", :in)
      end

      signal "PropertiesChanged" do
        arg("interface_name", "s")
        arg("changed_properties", "a{sv}")
        arg("invalidated_properties", "as")
      end
    end

    # interface "org.freedesktop.DBus.Introspectable" do
    #   method "Introspect" do
    #     arg("xml_data", "s", :out)
    #   end
    # end

    # interface "org.freedesktop.DBus.Peer" do
    #   method "Ping" do
    #   end

    #   method "GetMachineId" do
    #     arg("machine_uuid", "s", :out)
    #   end
    # end
  end

  defp get_all(interface_name, object) do
    types = []
  end
end
