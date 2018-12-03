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
    raise("No appropriate field definition for #{field_type}")
  end

  def map(field), do: raise("Field type expected to be atom got #{inspect(field)}")
end
