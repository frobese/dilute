defmodule DiluteTest do
  use ExUnit.Case
  doctest Dilute

  defmodule Types do
    use Absinthe.Schema.Notation
    import Dilute
    alias DiluteTest.{Post, Comment}

    ecto_object Post do
      field(:id, :integer)
      field(:name, :integer)
    end

    ecto_object Comment do
    end
  end

  defmodule Resolver do
    use Dilute.Resolver, types: MyAppWeb.Schema.Types, repo: DiluteTest.Repo
  end

  defmodule Schema do
    use Absinthe.Schema
    import_types(DiluteTest.Types)

    query do
      @desc "Get one Post"
      field :post, :post do
        resolve(&DiluteTest.Resolver.resolve/3)
      end

      @desc "Get all Posts"
      field :posts, list_of(:post) do
        resolve(&DiluteTest.Resolver.resolve/3)
      end
    end

    # query do
    #   MyWebApp.Schema.query_fields(:post, &Resolver.resolve/3)
    # end
  end

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
