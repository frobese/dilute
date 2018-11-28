defmodule DiluteTest.Environment.Absinthe.Schema do
  use Absinthe.Schema
  alias DiluteTest.Environment.Absinthe.{Types, Resolver}
  require Types

  import_types(Absinthe.Type.Custom)
  import_types(Types)

  query do
    Types.query_fields(:post, &Resolver.resolve/3)
  end
end
