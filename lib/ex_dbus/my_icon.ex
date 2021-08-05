defmodule MyIcon do
  use ExDBus.Service, service: "org.test.MyService"

  node "/MyObject" do
    node("/org/test/MyService/MySuperObject")

    node("/org/test/MyService/MySuperObjectG")

    node "/org/test/MyService/MyObject2" do
      node("/org/test/MyService/MyObject2/ObjectExtra")
    end

    interface "org.test.MyInterface" do
      method "HelloWorld" do
        IO.inspect("Called HelloWorld#1")
      end

      method "HelloWorld" do
        IO.inspect("Called HelloWorld #4")
        arg(:foo, :string, :in)
        arg("bar", :string, :out)
        annotation("org.freedesktop.DBus.Deprecated", true)
      end

      signal "MySignal" do
        arg(:foo, :string)
        arg(:bar, :string, :out)

        annotation("Signal annotation")

        arg(:foobar, :string) do
          annotation("Signal arg annotation")
        end
      end

      property "MyProperty", :string, :read do
        annotation("Property annotation")
        getter(&String.to_integer/1)
        setter(&Atom.to_string/1)
      end
    end

    node "/org/test/MyService/MyObject3" do
    end
  end
end
