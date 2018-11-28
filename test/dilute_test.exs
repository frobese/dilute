defmodule DiluteTest do
  use ExUnit.Case
  alias DiluteTest.Environment.Absinthe.Types

  doctest Dilute

  describe "Type definitions" do
    test "completeness" do
      assert %{:post => "Post", :comment => "Comment"} = Types.__absinthe_types__()
    end

    test "field integrity" do
      assert %{fields: fields} = Types.__absinthe_type__(:post)

      assert %{
               title: %{type: :string},
               # content: %{type: {:array, :string}},
               votes: %{type: :integer},
               #  flair: %{type: :binary}
               published: %{type: :boolean}

               # has_many(:comments, DiluteTest.Comment)
             } = fields
    end

    test "definition shadowing" do
      refute match?(
               %{fields: %{id: %{type: :integer}, name: %{type: :string}}},
               Types.__absinthe_type__(:post)
             )

      assert %{fields: %{id: %{type: :integer}, name: %{type: :integer}}} =
               Types.__absinthe_type__(:post)
    end
  end
end
