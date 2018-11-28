defmodule DiluteTest.Environment.Absinthe.Types do
  use Absinthe.Schema.Notation
  import Dilute
  alias DiluteTest.Environment.Ecto.{Post, Comment}

  ecto_object Post, exclude: :id do
    field(:rating, :float)
  end

  ecto_object Comment, exclude: :post do
  end
end
