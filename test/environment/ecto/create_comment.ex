defmodule DiluteTest.Environment.Ecto.CreateComment do
  use Ecto.Schema

  embedded_schema do
    field(:post_id, :integer)
    embeds_one(:comment, DiluteTest.Environment.Ecto.Comment)
  end
end
