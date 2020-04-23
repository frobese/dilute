defmodule DiluteTest.Environment.Absinthe.Types do
  use Absinthe.Schema.Notation
  import Dilute
  alias DiluteTest.Environment.Ecto.{Post, Comment, CreateComment, Message}

  defmodule SomeModuleNotCompilableModule do
    def hello do
      "world"
    end
  end

  dilute_object Post, exclude: :id do
    field(:rating, :float)

    field(:retrieved, :date,
      resolve: fn _parent, _args, _resolution -> {:ok, DateTime.utc_now()} end
    )
  end

  dilute_object Comment, exclude: [:post, :foo] do
    field(:last_viewed, :datetime)
  end

  dilute_object(Message)

  dilute_object(SomeModuleNotCompilableModule)

  dilute_object(DiluteTest.Environment.NoEctoSchema)

  dilute_input_object(Comment, exclude: :post)

  dilute_input_object(CreateComment, prefix: false)

  dilute_input_object(SomeModuleNotCompilableModule)
end
