defmodule ExDBus.Types do
  @type basic_type ::
          :byte
          | :boolean
          | :int16
          | :uint16
          | :int32
          | :uint32
          | :int64
          | :uint64
          | :double
          | :string
  @type array_type() :: array_type(any_type)
  @type array_type(t) :: list(t)
  @type any_type :: basic_type | array_type()

  def valid_types() do
    [
      :byte,
      :boolean,
      :int16,
      :uint16,
      :int32,
      :uint32,
      :int64,
      :uint64,
      :double,
      :string,
      :object_path,
      :variant,
      :struct,
      :array,
      :dict,
      :signature
    ]
  end

  def valid_type?(type) do
    Enum.member?(valid_types(), type)
  end

  def validate(type) do
    if valid_type?(type) do
      {:ok, type}
    else
      {:error, :invalid_type}
    end
  end
end
