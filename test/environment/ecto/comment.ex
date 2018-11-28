defmodule DiluteTest.Environment.Ecto.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:name, :string)

    belongs_to(:post, DiluteTest.Environment.Ecto.Post)

    timestamps()
  end
end
