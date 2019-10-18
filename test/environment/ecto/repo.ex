defmodule DiluteTest.Environment.Ecto.Repo do
  use Ecto.Repo, otp_app: :dilute, adapter: Ecto.Adapters.MyXQL
end
