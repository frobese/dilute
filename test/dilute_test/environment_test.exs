defmodule DiluteTest.EnvironmentTest do
  use ExUnit.Case

  alias DiluteTest.Environment.Ecto.Repo

  describe "Evironment Testing" do
    test "testing posts" do
      Repo.insert()
    end
  end
end
