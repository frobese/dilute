defmodule Dilute.Query do
  @moduledoc """
  Ecto query builder for `Resolution`s.
  """
  import Ecto.Query
  alias Dilute.Resolution

  defp apply_preload(query, assocs) do
    alias Ecto.Query.Builder.Preload
    Preload.apply(query, [], assocs)
  end

  @doc """
  Builds an `Ecto.Query` for the given `Resolution`.
  """
  @spec generate_query(
          Ecto.Queryable.t(),
          %Resolution{},
          list(),
          list(),
          {integer(), atom()} | nil
        ) :: {Ecto.Queryable.t(), list(), list()}
  def generate_query(query, resolution, bindings \\ [], assocs \\ [], current_bind \\ nil)

  def generate_query(query, %Resolution{} = res, [], [], nil) do
    # entry-point
    current_bind = {0, res.type}
    bindings = [current_bind]

    {query, _bindings, assocs} = generate_query(query, res, bindings, [], current_bind)
    apply_preload(query, assocs)
  end

  def generate_query(
        query,
        %Resolution{join: [h | rest]} = res,
        bindings,
        assocs,
        {curr_index, _curr_ref} = current_bind
      ) do
    # process joins
    next_bind = {length(bindings), h.type}
    {next_index, _} = next_bind

    bindings = bindings ++ [next_bind]

    {query, bindings, nested_assocs} =
      query
      |> join(:inner, [{bind, curr_index}], next in assoc(bind, ^h.ident))
      |> generate_query(h, bindings, [], next_bind)

    assocs = assocs ++ [{h.ident, {next_index, nested_assocs}}]
    generate_query(query, %Resolution{res | join: rest}, bindings, assocs, current_bind)
  end

  def generate_query(
        query,
        %Resolution{where: [{key, value} | rest]} = res,
        bindings,
        assocs,
        {curr_index, _curr_ref} = current_bind
      ) do
    # process where conditions
    query
    |> where([{bind, curr_index}], field(bind, ^key) == ^value)
    |> generate_query(%Resolution{res | where: rest}, bindings, assocs, current_bind)
  end

  # TODO: implement selects
  # def generate_query(
  #       query,
  #       %Resolution{select: [select | rest]} = res,
  #       bindings,
  #       assocs,
  #       {curr_index, _curr_ref} = current_bind
  #     ) do
  #   query
  #   |> select([ref: curr_index], field(ref, ^select))
  #   |> generate_query(%Resolution{res | select: rest}, bindings, assocs, current_bind)
  # end

  def generate_query(query, _resolution, bindings, assocs, _current_bind) do
    # final
    {query, bindings, assocs}
  end

  def index_to_name(index) do
    String.to_atom("b#{index}")
  end
end
