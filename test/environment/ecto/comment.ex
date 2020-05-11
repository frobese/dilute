defmodule DiluteTest.Environment.Ecto.Comment do
  use Ecto.Schema

  alias DiluteTest.Environment.Ecto.UnixTime

  schema "comments" do
    field(:content, :string)
    field(:votes, :integer)
    field(:votees, :map)
    field(:last_viewed, UnixTime)

    belongs_to(:post, DiluteTest.Environment.Ecto.Post)

    timestamps()
  end
end
