ExUnit.start()

defmodule DiluteTest.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:votes, :integer)
    field(:published, :boolean)

    has_many(:comments, DiluteTest.Comment)

    timestamps()
  end
end

defmodule DiluteTest.Comment do
  use Ecto.Schema

  schema "comments" do
    field(:name, :string)

    belongs_to(:post, DiluteTest.Post)

    timestamps()
  end
end
