defmodule DBusTrayIcon.MenuBar do
  use ExDBus.Schema

  node do
    interface "com.canonical.dbusmenu" do
      annotation("org.gtk.GDBus.C.Name", "Xml")
      property("Version", "u", :read)
      property("Status", "s", :read)
      property("TextDirection", "s", :read)
      property("IconThemePath", "as", :read)

      method "GetProperty" do
        arg("id", "i", :in)
        arg("property", "s", :in)
        arg("value", "v", :out)
      end

      method "GetLayout" do
        arg("parentId", "i", :in)
        arg("recursionDepth", "i", :in)
        arg("propertyNames", "as", :in)
        arg("revision", "u", :out)
        arg("item", "(ia{sv}av)", :out)
      end

      method "GetGroupProperties" do
        arg("ids", "ai", :in)
        arg("propertyNames", "as", :in)
        arg("properties", "a(ia{sv})", :out)
      end

      method "Event" do
        arg("id", "i", :in)
        arg("eventId", "s", :in)
        arg("data", "v", :in)
        arg("timestamp", "u", :in)
        annotation("org.freedesktop.DBus.Method.NoReply", "true")
      end

      method "EventGroup" do
        arg("events", "a(isvu)", :in)
        arg("idErrors", "ai", :out)
      end

      method "AboutToShow" do
        arg("id", "i", :in)
        arg("needUpdate", "b", :out)
      end

      method "AboutToShowGroup" do
        arg("ids", "ai", :in)
        arg("updatesNeeded", "ai", :out)
        arg("idErrors", "ai", :out)
      end

      signal "ItemsPropertiesUpdated" do
        arg("updatedProps", "a(ia{sv})")
        arg("removedProps", "a(ias)")
      end

      signal "LayoutUpdated" do
        arg("parent", "i")
        arg("revision", "u")
      end

      signal "ItemActivationRequested" do
        arg("id", "i")
        arg("timeStamp", "u")
      end
    end
  end
end
