defmodule DiluteTest.Environment.Ecto.Message do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:lines, {:array, :string})
  end
end
