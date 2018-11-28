defmodule DiluteTest.Environment.Absinthe.Types do
  use Absinthe.Schema.Notation
  import Dilute
  alias DiluteTest.Environment.Ecto.{Post, Comment}

  ecto_object Post do
  end

  ecto_object Comment do
  end
end
