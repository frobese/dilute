defmodule Dilute.Resolver do
  @moduledoc """
  The `Resolver` implements the `resolve/3` function for the given types and their repo.

  The resolver requires the parent element to be `%{}` and build the query and submits the request based on the `Resolution` derived from the `Absinthe.Resolution`, `args` are not evaluated since they are included in the Absinthe resolution.
  """
  require Logger
  alias Dilute.{Resolution, Query}

  defmacro __using__(types: mod, repo: repo) do
    quote do
      alias Dilute
      require Logger

      def resolve(
            %{},
            _args,
            resolution
          ) do
        resolution =
          resolution
          |> Resolution.derive_resolution()

        query =
          unquote(mod).__object__(:schema, resolution.type)
          |> Query.generate_query(resolution)

        result =
          case resolution do
            %Resolution{cardinality: :many} ->
              query
              |> unquote(repo).all()

            %Resolution{cardinality: :one} ->
              query
              |> unquote(repo).one()
          end

        {:ok, result}
      rescue
        Ecto.MultipleResultsError ->
          {:error, "Too many results returned"}
      end
    end
  end
end
