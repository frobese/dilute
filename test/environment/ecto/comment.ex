defmodule DiluteTest.Environment.Ecto.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:content, :string)
    field(:votes, :integer)

    belongs_to(:post, DiluteTest.Environment.Ecto.Post)

    timestamps()
  end
end
