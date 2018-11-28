defmodule DiluteTest.Environment.Ecto.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def up do
    create table(:posts) do
      add(:title, :string)
      add(:votes, :integer)
      add(:published, :boolean)
      add(:rating, :integer)

      timestamps()
    end
  end

  def down do
    drop table(:posts)
  end
end
