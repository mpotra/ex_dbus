defmodule Examples.Schemas.Example1 do
  use ExDBus.Schema

  node do
    interface "org.example.MyWindowInterface" do
      property("Title", "s", :read)
      property("WindowId", "i", :read) do
        annotation("org.example.SomeInterface", "some value")
      end
      property("Description", "s", :readwrite)

      method "SetTitle" do
       arg("new_title", "s", :in)
      end

      signal("NewTitle")
      signal "NewStatus" do
        arg("status", "s")
      end
    end

    node "/Element" do
      interface "org.example.ElementInterface" do
        property("Name", "s", :read)

        method "SetName" do
          arg("new_name", "s", :in)
        end
      end
    end
  end
end
