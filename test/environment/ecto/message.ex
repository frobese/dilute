defmodule DiluteTest.Environment.Ecto.Message do
  use Ecto.Schema

  embedded_schema do
    field(:lines, {:array, :string})
  end
end
