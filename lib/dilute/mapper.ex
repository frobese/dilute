defmodule Dilute.Mapper do
  @moduledoc """
  Type-mapper matching ecto types onto absinthe compatible Types.
  """

  def map(:id), do: :id
  def map(:binary_id), do: :id
  def map(:integer), do: :integer
  def map(:float), do: :float
  def map(:boolean), do: :boolean
  def map(:string), do: :string
  def map(:decimal), do: :decimal
  def map(:date), do: :date
  def map(:time), do: :time
  def map(:naive_datetime), do: :naive_datetime
  def map(:naive_datetime_usec), do: :naive_datetime
  def map(:utc_datetime), do: :datetime
  def map(:utc_datetime_usec), do: :datetime

  def map(field_type) when is_atom(field_type) do
    if ecto_custom_type?(field_type) do
      {:custom, field_type}
    else
      raise("The given type does not seam to be an ecto custom type got: #{field_type}")
      # raise("No appropriate field definition for #{field_type}")
    end
  end

  def map(field), do: raise("Field type expected to be atom got #{inspect(field)}")

  defp ecto_custom_type?(module) do
    Code.ensure_compiled?(module) and
      function_exported?(module, :cast, 1) and
      function_exported?(module, :dump, 1) and
      function_exported?(module, :load, 1) and
      function_exported?(module, :type, 0)
  end
end
