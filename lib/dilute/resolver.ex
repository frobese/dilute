defmodule Dilute.Resolver do
  @moduledoc """
  Using the Resolver implements the `resolve/3` function which evaluates a given resolution based on the given object definitions.
  """
  require Logger
  alias Dilute.{Resolution, Query}

  defmacro __using__(types: mod, repo: repo) do
    quote do
      alias Dilute
      require Logger

      def resolve(
            %{},
            args,
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
            %Resolution{cardinality: :one} ->
              query
              |> unquote(repo).all()

            %Resolution{cardinality: :many} ->
              query
              |> unquote(repo).one()
          end

        {:ok, result}
      rescue
        Ecto.MultipleResultsError ->
          {:error, "To many results returned"}
      end
    end
  end
end
