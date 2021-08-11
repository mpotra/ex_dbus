defmodule ExDBus.Interfaces do
  use ExDBus.Schema
  alias ExDBus.Interfaces.{Introspectable, Peer, Properties}

  node do
    import from(Introspectable)
    import from(Peer)
    import from(Properties)
  end
end
