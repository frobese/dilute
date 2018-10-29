defmodule Dilute.Query do
  import Ecto.Query
  alias Dilute.Resolution

  defp apply_preload(query, assocs) do
    alias Ecto.Query.Builder.Preload
    Preload.apply(query, [], assocs)
  end

  @spec gen_query(Ecto.Queryable.t(), %Resolution{}, list(), list(), {integer(), atom()} | nil) ::
          {Ecto.Queryable.t(), list(), list()}
  def gen_query(query, resolution, bindings \\ [], assocs \\ [], current_bind \\ nil)

  def gen_query(query, %Resolution{} = res, [], [], nil) do
    current_bind = {0, res.type}
    bindings = [current_bind]

    {query, _bindings, assocs} = gen_query(query, res, bindings, [], current_bind)
    apply_preload(query, assocs)
  end

  def gen_query(
        query,
        %Resolution{join: [h | rest]} = res,
        bindings,
        assocs,
        {curr_index, _curr_ref} = current_bind
      ) do
    next_bind = {length(bindings), h.type}
    {next_index, _} = next_bind

    bindings = bindings ++ [next_bind]

    {query, bindings, nested_assocs} =
      query
      |> join(:inner, [ref: curr_index], next in assoc(ref, ^h.ident))
      |> gen_query(h, bindings, [], next_bind)

    assocs = assocs ++ [{h.ident, {next_index, nested_assocs}}]
    gen_query(query, %Resolution{res | join: rest}, bindings, assocs, current_bind)
  end

  def gen_query(
        query,
        %Resolution{where: [{key, value} | rest]} = res,
        bindings,
        assocs,
        {curr_index, _curr_ref} = current_bind
      ) do
    query
    |> where([ref: curr_index], field(ref, ^key) == ^value)
    |> gen_query(%Resolution{res | where: rest}, bindings, assocs, current_bind)
  end

  # TODO: implement selects
  # def gen_query(
  #       query,
  #       %Resolution{select: [select | rest]} = res,
  #       bindings,
  #       assocs,
  #       {curr_index, _curr_ref} = current_bind
  #     ) do
  #   query
  #   |> select([ref: curr_index], field(ref, ^select))
  #   |> gen_query(%Resolution{res | select: rest}, bindings, assocs, current_bind)
  # end

  def gen_query(query, _resolution, bindings, assocs, _current_bind) do
    {query, bindings, assocs}
  end

  def generate_query(
        query,
        resolution,
        args \\ %{},
        bindings \\ [],
        assocs \\ [],
        current_bind \\ nil
      )

  def generate_query(query, {bind, nesting}, args, bindings, [], nil) do
    current_bind = {length(bindings), bind}
    bindings = bindings ++ [current_bind]

    {query, _binds, assocs} = generate_query(query, nesting, args, bindings, [], current_bind)
    apply_preload(query, assocs)
  end

  def generate_query(
        query,
        [{ref, {bind, nesting}} | rest],
        args,
        bindings,
        assocs,
        {index, _curr_bind} = current_bind
      ) do
    next_bind = {length(bindings), bind}
    {next_index, _} = next_bind

    bindings = bindings ++ [next_bind]

    query =
      Enum.reduce(args, query, fn {key, value}, query ->
        where(query, [ref: index], field(ref, ^key) == ^value)
      end)

    {query, bindings, nested_assocs} =
      query
      |> join(:inner, [ref: index], next in assoc(ref, ^ref))
      |> generate_query(nesting, %{}, bindings, [], next_bind)

    assocs = assocs ++ [{ref, {next_index, nested_assocs}}]

    generate_query(query, rest, %{}, bindings, assocs, current_bind)
  end

  def generate_query(query, [], _args, bindings, assocs, _curr_bind) do
    {query, bindings, assocs}
  end
end
