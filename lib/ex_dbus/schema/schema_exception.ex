defmodule ExDBus.Schema.SchemaException do
  import Kernel, except: [reraise: 2]

  defexception message: "NodeDefinedException",
               meta: []

  @impl true
  def exception({message, meta}) do
    %__MODULE__{message: message, meta: meta}
  end

  def exception(message) do
    %__MODULE__{message: message}
  end

  def stacktrace(%__MODULE__{meta: [line: line_number]}, env) do
    env_location = Macro.Env.location(env)

    location =
      []
      |> Keyword.put(:line, line_number)
      |> Keyword.put(:file, Keyword.get(env_location, :file))

    stacktrace = Macro.Env.stacktrace(env)

    [{module, type, index, _} | _] = stacktrace
    head = {module, type, index, location}

    [head | stacktrace]
  end

  def reraise(%__MODULE__{message: message} = e, env) do
    Kernel.reraise(message, __MODULE__.stacktrace(e, env))
  end
end
