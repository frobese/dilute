defmodule DiluteTest do
  use ExUnit.Case
  alias DiluteTest.Environment.Absinthe.Types

  doctest Dilute

  describe "Object definition testing" do
    test "completeness" do
      assert %{:post => "Post", :comment => "Comment", :message => "Message"} =
               Types.__absinthe_types__()
    end

    test "field integrity" do
      assert %{fields: fields} = Types.__absinthe_type__(:post)

      assert %{
               title: %{type: :string},
               votes: %{type: :integer},
               published: %{type: :boolean},
               updated_at: %{type: :naive_datetime},
               inserted_at: %{type: :naive_datetime},
               rating: %{type: :float},
               retrieved: %{type: :date},
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

    test "array fields" do
      assert %{fields: %{lines: %{type: %Absinthe.Type.List{of_type: :string}}}} =
               Types.__absinthe_type__(:message)
    end

    test "leave modules undefined" do
      types = Types.__absinthe_types__()
      assert Map.has_key?(types, :some_module_not_compilable_module)
      assert Map.has_key?(types, :no_ecto_schema)
    end
  end
end
