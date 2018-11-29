use Mix.Config

config :dilute, DiluteTest.Environment.Ecto.Repo,
  adapter: Ecto.Adapters.MySQL,
  pool_timeout: 9000,
  timeout: 15000,
  server: "localhost",
  port: 4001,
  database: "dilute_test",
  username: "root",
  password: "mypass"

#import_config "dev.secrets.exs"
