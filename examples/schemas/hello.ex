defmodule Examples.Schemas.HelloExample do
  use ExDBus.Schema

  node do
    interface "org.example.HelloInterface" do
      method "SayHello" do
        arg("name", "s", :in)
        arg("message", "s", :out)
        callback(&__MODULE__.say_hello/2)
      end
    end
  end

  defp say_hello(name, _) do
    {:ok, [:string], ["Hello #{name}"]}
  end
end
