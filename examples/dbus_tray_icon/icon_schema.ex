defmodule DBusTrayIcon.IconSchema do
  use ExDBus.Schema

  node do
    node "/MenuBar" do
      import from(ExDBus.Interfaces)
      import from(DBusTrayIcon.MenuBar)
    end

    import from(ExDBus.Interfaces)

    node "/StatusNotifierItem" do
      import from(ExDBus.Interfaces)
      import from(DBusTrayIcon.StatusNotifierItem)
    end

    node "/Hello" do
      import from(ExDBus.Interfaces)

      interface "org.example.Hello" do
        property("Name", "s", :read) do
          getter(&__MODULE__.placeholder_name_r/1)
        end

        property("NameRW", "s", :readwrite) do
          getter(&__MODULE__.placeholder_name_rw/1)
          setter(&__MODULE__.placeholder_name_w/2)
        end

        property("NameW", "s", :write) do
          getter(&__MODULE__.placeholder_name_rw/1)
          setter(&__MODULE__.placeholder_name_w/2)
        end

        method "say_hello" do
          arg("name", "s", :in)
          arg("age", "i", :in)
          arg("reply1", "s", :out)
          arg("reply2", "i", :out)
          callback(&__MODULE__.say_hello_si/1)
        end

        method "say_hello" do
          arg("name", "s", :in)
          arg("reply", "s", :out)
          callback(&__MODULE__.say_hello_s/1)
        end

        method "say_hello" do
          arg("age", "i", :in)
          arg("reply", "s", :out)
          callback(&__MODULE__.say_hello_i/1)
        end

        method "say_hello" do
          arg("list", "a(i)", :in)
        end
      end
    end
  end

  def placeholder_name_r(_) do
    "MikeStatic"
  end

  def placeholder_name_rw(_) do
    "MikeRWStatic"
  end

  def placeholder_name_w(_, v) do
    IO.inspect(v, label: "IconSchema write name")
    "MikeRWStatic"
  end

  def say_hello_si({name, age}) do
    {:ok, [:string, :int32], ["Hello #{name} of age #{age}", 22]}
  end

  def say_hello_s(name) do
    {:ok, [:string], ["Hello #{name}"]}
  end

  def say_hello_i(age) do
    {:ok, [:string], ["Hello person of age #{age}"]}
  end
end
