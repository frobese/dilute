defmodule Dilute.Resolution do
  @moduledoc """
  Query-esque representation for `Absinthe.Resolution`s.
  """
  require Logger
  alias Absinthe.Resolution
  alias Absinthe.Blueprint.Document
  alias Absinthe.Type.{Field, List}

  @absinthe_types [
    :id,
    :integer,
    :float,
    :boolean,
    :string,
    :decimal,
    :date,
    :time,
    :naive_datetime,
    :datetime
  ]

  defstruct [
    :ident,
    :type,
    select: [],
    where: [],
    join: [],
    type_module: nil,
    cardinality: nil
  ]

  @doc """
  Derives the `Dilute.Resolution` for the given `Absinthe.Resolution`
  """
  @spec derive_resolution(nil, %Resolution{}) :: %__MODULE__{}
  @spec derive_resolution(%__MODULE__{} | nil, %Document.Field{}) :: %__MODULE__{}
  def derive_resolution(acc \\ nil, select)

  def derive_resolution(nil, %Resolution{definition: field}) do
    derive_resolution(field)
  end

  def derive_resolution(nil, %Document.Field{
        schema_node: node,
        selections: select,
        argument_data: argument_data
      }) do
    {type, cardinality} =
      node
      |> type()

    if type in @absinthe_types do
      raise "Root Type has to be a schema"
    else
      %__MODULE__{
        ident: node.identifier,
        type: type,
        cardinality: cardinality,
        type_module: module(node, type),
        where: Map.to_list(argument_data)
      }
      |> derive_resolution(select)
    end
  end

  def derive_resolution(%__MODULE__{} = res, %Document.Field{
        schema_node: node,
        selections: select,
        argument_data: argument_data
      }) do
    {type, cardinality} =
      node
      |> type()

    if node.identifier in joins(res) do
      %__MODULE__{
        res
        | join: [
            derive_resolution(
              %__MODULE__{
                ident: node.identifier,
                type: type,
                cardinality: cardinality,
                type_module: module(node, type),
                where: Map.to_list(argument_data)
              },
              select
            )
            | res.join
          ]
      }
    else
      %__MODULE__{res | select: [node.identifier | res.select]}
    end
  end

  def derive_resolution(res, []), do: res

  def derive_resolution(res, [h | t]) do
    res
    |> derive_resolution(h)
    |> derive_resolution(t)
  end

  defp type(%Field{type: %List{of_type: type}}), do: {type, :many}
  defp type(%Field{type: type}), do: {type, :one}

  defp module(%{__reference__: %{module: module}}, type) do
    cond do
      function_exported?(module, :__object__, 2) ->
        module

      function_exported?(module, :__absinthe_type__, 1) ->
        Absinthe.Schema.lookup_type(module, type)
        |> module(type)

      true ->
        nil
    end
  end

  def joins(%__MODULE__{type: type, type_module: module}) when not is_nil(type) do
    module.__object__(:joins, type)
  rescue
    FunctionClauseError -> []
  end

  def joins(_resolution), do: []
end
