defmodule Dilute.Resolution do
  require Logger
  alias Absinthe.Resolution
  alias Absinthe.Blueprint.Document
  alias Absinthe.Type.{Field, List}

  @absinthe_types [
    :boolean,
    :float,
    :string,
    :id,
    :integer
  ]

  defstruct [
    :ident,
    :type,
    select: [],
    where: [],
    join: [],
    cardinality: nil
  ]

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
      |> get_type()

    if type in @absinthe_types do
      raise "Root Type has to be a schema"
    else
      %__MODULE__{
        ident: node.identifier,
        type: type,
        cardinality: cardinality,
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
      |> get_type()

    if type in @absinthe_types do
      %__MODULE__{res | select: [node.identifier | res.select]}
    else
      %__MODULE__{
        res
        | join: [
            derive_resolution(
              %__MODULE__{
                ident: node.identifier,
                type: type,
                cardinality: cardinality,
                where: Map.to_list(argument_data)
              },
              select
            )
            | res.join
          ]
      }
    end
  end

  def derive_resolution(res, []), do: res

  def derive_resolution(res, [h | t]) do
    res
    |> derive_resolution(h)
    |> derive_resolution(t)
  end

  defp get_type(%Field{type: %List{of_type: type}}), do: {type, :many}
  defp get_type(%Field{type: type}), do: {type, :one}
end
