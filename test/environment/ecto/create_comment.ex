defmodule DiluteTest.Environment.Ecto.CreateComment do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:post_id, :integer)
    embeds_one(:comment, DiluteTest.Environment.Ecto.Comment)
  end
end
