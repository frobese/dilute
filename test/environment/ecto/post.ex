defmodule DiluteTest.Environment.Ecto.Post do
  use Ecto.Schema

  schema "post" do
    field(:title, :string)
    field(:votes, :integer)
    field(:published, :boolean)

    has_many(:comments, DiluteTest.Environment.Ecto.Comment)

    timestamps()
  end
end
