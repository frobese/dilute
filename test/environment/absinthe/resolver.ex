defmodule DiluteTest.Environment.Absinthe.Resolver do
  use Dilute.Resolver,
    types: DiluteTest.Environment.Absinthe.Types,
    repo: DiluteTest.Environment.Ecto.Repo
end
