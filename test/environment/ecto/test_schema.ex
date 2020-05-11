defmodule DiluteTest.Environment.Ecto.TestSchema do
  use Ecto.Schema

  alias DiluteTest.Environment.Ecto.UnixTime

  @primary_key false
  embedded_schema do
    field(:some_id, :id)
    # field(:some_binary_id, :binary_id)
    field(:some_integer, :integer)
    field(:some_float, :float)
    field(:some_boolean, :boolean)
    field(:some_string, :string)
    # field(:some_binary, :binary)
    field(:some_array, {:array, :integer})
    # field( :some_map, :map		)
    # field( :some_{:, {:map, inner_type}	)
    field(:some_decimal, :decimal)
    field(:some_date, :date)
    field(:some_time, :time)
    # field(:some_time_usec, :time_usec)
    field(:some_naive_datetime, :naive_datetime)
    # field(:some_naive_datetime_usec, :naive_datetime_usec)
    field(:some_utc_datetime, :utc_datetime)
    # field(:some_utc_datetime_usec, :utc_datetime_usec)
    field(:custom_type, UnixTime)
  end
end
