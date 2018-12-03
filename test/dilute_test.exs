defmodule DiluteTest do
  use ExUnit.Case
  alias DiluteTest.Environment.Absinthe.Types

  doctest Dilute

  describe "Object definition testing" do
    test "completeness" do
      assert %{:post => "Post", :comment => "Comment"} = Types.__absinthe_types__()
    end

    test "field integrity" do
      assert %{fields: fields} = Types.__absinthe_type__(:post)

      assert %{
               title: %{type: :string},
               votes: %{type: :integer},
               published: %{type: :boolean},
               updated_at: %{type: :naive_datetime},
               inserted_at: %{type: :naive_datetime},
               #  rating: %{type: :float},
               comments: _
             } = fields
    end

    test "definition shadowing" do
      refute match?(
               %{fields: %{rating: %{type: :integer}}},
               Types.__absinthe_type__(:post)
             )

      assert %{fields: %{rating: %{type: :float}}} = Types.__absinthe_type__(:post)
    end

    test "excludes" do
      refute match?(
               %{fields: %{post: _}},
               Types.__absinthe_type__(:comment)
             )
    end
  end
end
