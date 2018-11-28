ExUnit.start()

{:ok, _pid} = DiluteTest.Environment.Ecto.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(DiluteTest.Environment.Ecto.Repo, :manual)
