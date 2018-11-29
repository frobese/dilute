defmodule DiluteTest.EnvironmentTest do
  use ExUnit.Case

  alias DiluteTest.Environment.Ecto.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "Environment Testing" do
    test "testing posts insert" do
      entity = %DiluteTest.Environment.Ecto.Post{title: "Hallo Welt"}
      assert {:ok, _} = Repo.insert(entity)
    end

    test "testing comments insert" do
      entity = %DiluteTest.Environment.Ecto.Comment{name: "Jan"}
      assert {:ok, _} = Repo.insert(entity)
    end

    test "testing constraint violation on comment insert" do
      entity = %DiluteTest.Environment.Ecto.Comment{name: "Jan", post_id: 3}
      assert_raise(Ecto.ConstraintError, fn -> Repo.insert(entity) end)
    end
  end
end
