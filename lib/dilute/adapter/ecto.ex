defmodule Dilute.Adapter.Ecto do
  @moduledoc false
  use Dilute.Adapter

  @impl Dilute.Adapter
  def applicable?(module) do
    with true <-
           function_exported?(module, :__schema__, 1) and
             function_exported?(module, :__schema__, 2),
         _ <- module.__schema__(:primary_key) do
      true
    else
      _ -> false
    end
  rescue
    FunctionClauseError -> false
  end

  @impl Dilute.Adapter
  def fields(module) do
    fields =
      Enum.map(module.__schema__(:fields), fn field ->
        case module.__schema__(:type, field) do
          {:embed, %Ecto.Embedded{related: related, cardinality: cardinality}} ->
            {field, cardinality, :"$module", related}

          {:map, type} ->
            {field, :may, :invalid, type}

          :map ->
            {field, :many, :invalid, :any}

          {:array, type} ->
            {field, :many, map_type(type), type}

          type ->
            {field, :one, map_type(type), type}
        end
      end)

    assocs =
      Enum.map(module.__schema__(:associations), fn field ->
        case module.__schema__(:association, field) do
          %Ecto.Association.BelongsTo{related: related, cardinality: cardinality} ->
            {field, cardinality, :"$module", related}

          %Ecto.Association.Has{related: related, cardinality: cardinality} ->
            {field, cardinality, :"$module", related}
        end
      end)

    fields ++ assocs
  end

  @identical_types [
    :id,
    :integer,
    :float,
    :boolean,
    :string,
    :decimal,
    :date,
    :time,
    :naive_datetime
  ]

  def map_type(:binary_id) do
    :string
  end

  def map_type(:time_usec) do
    :time
  end

  def map_type(:naive_datetime_usec) do
    :naive_datetime
  end

  def map_type(:utc_datetime) do
    :datetime
  end

  def map_type(:utc_datetime_usec) do
    :datetime
  end

  def map_type(type) when type in @identical_types do
    type
  end

  def map_type(field_type) when is_atom(field_type) do
    if ecto_custom_type?(field_type) do
      map_type(field_type.type())
    else
      :invalid
    end
  end

  def map_type(_field) do
    :invalid
  end

  defp ecto_custom_type?(module) do
    {:module, module} == Code.ensure_compiled(module) and
      function_exported?(module, :cast, 1) and
      function_exported?(module, :dump, 1) and
      function_exported?(module, :load, 1) and
      function_exported?(module, :type, 0)
  end
end
