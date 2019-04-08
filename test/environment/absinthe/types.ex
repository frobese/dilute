defmodule DiluteTest.Environment.Absinthe.Types do
  use Absinthe.Schema.Notation
  import Dilute
  alias DiluteTest.Environment.Ecto.{Post, Comment, Create_Comment}

  ecto_object Post, exclude: :id do
    field(:rating, :float)

    field(:retrieved, :date,
      resolve: fn _parent, _args, _resolution -> {:ok, DateTime.utc_now()} end
    )
  end

  ecto_object Comment, exclude: [:post, :last_viewed] do
  end

  # ecto_input_object Comment, exclude: [:post, :last_viewed] do
  # end

  # ecto_input_object Create_Comment, prefix: false do
  # end
end
