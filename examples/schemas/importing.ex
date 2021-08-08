defmodule Examples.Schemas.Importing do
  use ExDBus.Schema
  alias Examples.Schemas.HelloExample
  alias ExDBus.Interfaces.Introspectable

  node do
    import from(HelloExample)
    import from(Introspectable)
    # import from(Introspectable), path: "/"

    # import from(Introspectable), path: "/" do
    #   interface("org.freedesktop.DBus.Introspectable")
    # end

    # import from(Introspectable), path: "/" do
    #   interface("org.freedesktop.DBus.Introspectable", as: "org.NOMORE.Interface")
    # end

    # import from(Introspectable) do
    #   interface("org.freedesktop.DBus.Introspectable")
    #   interface("org.freedesktop.DBus.Introspectable", path: "/")
    #   interface("org.freedesktop.DBus.Introspectable", as: "org.Introspectable")
    #   interface("org.freedesktop.DBus.Introspectable", path: "/", as: "org.Introspectable")
    #   interface("org.freedesktop.DBus.Introspectable", as: "org.Introspectable", path: "/")
    # end

    import from(Examples.Schemas.Example1) do
      interface("org.example.MyWindowInterface", path: "/")
      interface("org.example.ElementInterface", path: "/Element")
      # interface("org.example.ElementInterface", path: "/Element", as: "MyElementInterface")
    end


    interface "org.example.MyInterface" do
      property("Category", "s", :read)
      property("Id", "s", :read)
    end
  end
end
