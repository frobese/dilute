defmodule Dilute.Mapper do
  @moduledoc """
  Type-mapper matching ecto types onto absinthe compatible Types.
  """
  # import Absinthe.Schema.Notation, only: [list_of: 1]

  def map(:id), do: :id
  def map(:binary_id), do: :id
  def map(:integer), do: :integer
  def map(:float), do: :float
  def map(:boolean), do: :boolean
  def map(:string), do: :string
  # def map(:binary), do: :string
  # def map(:map), do:
  def map(:decimal), do: :decimal
  def map(:date), do: :date
  def map(:time), do: :time
  def map(:naive_datetime), do: :naive_datetime
  def map(:naive_datetime_usec), do: :naive_datetime
  def map(:utc_datetime), do: :datetime
  def map(:utc_datetime_usec), do: :datetime

  # def map({:array, type}) do
  #   type
  #   |> map()
  #   |> list_of()
  # end

  # {:map, inner_type}	map
end
