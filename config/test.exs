use Mix.Config

config :dilute, ecto_repos: [DiluteTest.Environment.Ecto.Repo]

config :dilute, DiluteTest.Environment.Ecto.Repo,
  adapter: Ecto.Adapters.MySQL,
  pool_timeout: 9000,
  timeout: 15000,
  server: "localhost",
  port: 4001,
  database: "dilute_test",
  username: "root",
  password: "mypass",
  pool: Ecto.Adapters.SQL.Sandbox

# import_config "test.secrets.exs"
