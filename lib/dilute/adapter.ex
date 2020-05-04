defmodule Dilute.Adapter do
  @moduledoc """
  Adapters serve as a translator between schema libaries and Dilute.
  One of the build in Adapters is the Ecto adapter, which can be used to derive absinthe object definitions from Ecto schemas.

  The callbacks that have to be implemented are:

  `applicable?/1` - Checks if the given module is a valid subject for the adapter and returns `true`/`false`

      iex> Dilute.Adapter.Ecto.applicable?(Comment)
      true
      iex> Dilute.Adapter.Ecto.applicable?(NoEctoSchema)
      false

  `fields/1` - Returns a list of fields wich can be processed by Dilute afterwards.
  Each field is represented as a tuple `{field, cardinality, type, related}`.

    - `field` is the atom identifier of the field
    - `cardinality` either `:one` or `:many`
    - `type` a valid absinthe type. If the field references another object type has to be `:"$module"`
    - `related` either the source type (for an ecto `:utc_datetime` which is mapped to `:datetime` this would be `:utc_datetime`), or should it be an reference to another module this has to be the respective module.


      iex> Dilute.Adapter.Ecto.fields(Comment)
      [
        {:id, :one, :id, :id},
        {:content, :one, :string, :string},
        {:votes, :one, :integer, :integer},
        {:last_viewed, :one, :integer, DiluteTest.Environment.Ecto.UnixTime},
        {:post_id, :one, :id, :id},
        {:inserted_at, :one, :naive_datetime, :naive_datetime},
        {:updated_at, :one, :naive_datetime, :naive_datetime},
        {:post, :one, :"$module", DiluteTest.Environment.Ecto.Post}
      ]
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Dilute.Adapter

      alias Dilute.AdapterError
    end
  end

  @callback applicable?(module) :: boolean()
  @callback fields(module) :: list({atom(), :one | :many, atom(), atom()})
end
