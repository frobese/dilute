defmodule DiluteTest.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias DiluteTest.Environment.Ecto.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DiluteTest.Environment.Ecto.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DiluteTest.Environment.Ecto.Repo, {:shared, self()})
    end

    :ok
  end
end
