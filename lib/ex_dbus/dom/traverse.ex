defmodule ExDBus.Tree.Traverse do
  @moduledoc """
  Tree traversal functions.
  Blatanly copied and adjusted from Elixir's Macro module.
  """
  use ExDBus.Spec, prefix: false

  @doc """
  Performs a depth-first traversal of definitions
  using an accumulator.
  """
  @spec traverse(
          definition(),
          any,
          (definition(), any -> {definition(), any}),
          (definition(), any -> {definition(), any})
        ) :: {definition(), any}
  def traverse(definition, acc, pre, post) when is_function(pre, 2) and is_function(post, 2) do
    {definition, acc} = pre.(definition, acc)
    do_traverse(definition, acc, pre, post)
  end

  defp do_traverse({:object, path, children}, acc, pre, post) do
    {children, acc} = do_traverse_list(children, acc, pre, post)
    post.({:object, path, children}, acc)
  end

  defp do_traverse({:interface, name, children}, acc, pre, post) do
    {children, acc} = do_traverse_list(children, acc, pre, post)
    post.({:interface, name, children}, acc)
  end

  defp do_traverse({:method, name, children, handle}, acc, pre, post) do
    {children, acc} = do_traverse_list(children, acc, pre, post)
    post.({:method, name, children, handle}, acc)
  end

  defp do_traverse({:signal, name, children}, acc, pre, post) do
    {children, acc} = do_traverse_list(children, acc, pre, post)
    post.({:signal, name, children}, acc)
  end

  defp do_traverse({:property, name, type, access, annotations, handle}, acc, pre, post) do
    {annotations, acc} = do_traverse_list(annotations, acc, pre, post)
    post.({:property, name, type, access, annotations, handle}, acc)
  end

  defp do_traverse({:annotation, _, _} = annotation, acc, _pre, post) do
    post.(annotation, acc)
  end

  defp do_traverse({:argument, name, type, direction, annotations}, acc, pre, post) do
    {annotations, acc} = do_traverse_list(annotations, acc, pre, post)
    post.({:argument, name, type, direction, annotations}, acc)
  end

  # Generic list traverse function, using a given function to recurse
  defp do_traverse_list([], acc, _, _) do
    {[], acc}
  end

  defp do_traverse_list([head | tail], acc, pre, post) do
    {head, acc} = traverse(head, acc, pre, post)
    {tail, acc} = do_traverse_list(tail, acc, pre, post)
    {[head | tail], acc}
  end

  # ----

  @doc """
  Performs a depth-first, pre-order traversal of definitions.
  """
  @spec prewalk(definition(), (definition() -> definition())) :: definition()
  def prewalk(definition, fun) when is_function(fun, 1) do
    elem(prewalk(definition, nil, fn x, nil -> {fun.(x), nil} end), 0)
  end

  @doc """
  Performs a depth-first, pre-order traversal of definitions
  using an accumulator.
  """
  @spec prewalk(definition(), any, (definition(), any -> {definition(), any})) ::
          {definition(), any}
  def prewalk(definition, acc, fun) when is_function(fun, 2) do
    traverse(definition, acc, fun, fn x, a -> {x, a} end)
  end

  @doc """
  Performs a depth-first, post-order traversal of definitions.
  """
  @spec postwalk(definition(), (definition() -> definition())) :: definition()
  def postwalk(definition, fun) when is_function(fun, 1) do
    elem(postwalk(definition, nil, fn x, nil -> {fun.(x), nil} end), 0)
  end

  @doc """
  Performs a depth-first, post-order traversal of definitions
  using an accumulator.
  """
  @spec postwalk(definition(), any, (definition(), any -> {definition(), any})) ::
          {definition(), any}
  def postwalk(definition, acc, fun) when is_function(fun, 2) do
    traverse(definition, acc, fn x, a -> {x, a} end, fun)
  end
end
