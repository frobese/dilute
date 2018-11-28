defmodule DiluteTest.Environment.Ecto.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def up do
    create table(:comments) do
      add(:content, :string)
      add(:votes, :integer)
      add(:post_id, references(:posts))

      timestamps()
    end
  end

  def down do
    drop(table(:comments))
  end
end
