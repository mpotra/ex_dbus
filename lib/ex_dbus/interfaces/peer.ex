defmodule ExDBus.Interfaces.Peer do
  use ExDBus.Schema

  node do
    interface "org.freedesktop.DBus.Peer" do
      method "Ping" do
      end

      method "GetMachineId" do
        arg("machine_uuid", "s", :out)
      end
    end
  end
end
