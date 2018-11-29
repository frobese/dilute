defmodule DiluteTest.Environment.Ecto.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def up do
    create table(:comments) do
      add(:name, :string)
      add(:post_id, :integer)

      timestamps()
    end

    alter table(:comments) do
      modify :post_id, references(:posts)
    end
  end

  def down do
    drop table(:comments)
  end
end
