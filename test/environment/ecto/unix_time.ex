defmodule DiluteTest.Environment.Ecto.UnixTime do
  @behaviour Ecto.Type

  def type, do: :integer

  def cast(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp, :second) do
      {:error, _} -> :error
      ok -> ok
    end
  end

  def cast(%DateTime{} = datetime) do
    {:ok, datetime}
  end

  def cast(_), do: :error

  def load(timestamp) when is_integer(timestamp) do
    case DateTime.from_unix(timestamp, :second) do
      {:error, _} -> :error
      ok -> ok
    end
  end

  def load(_), do: :error

  def dump(%DateTime{} = datetime) do
    {:ok, DateTime.to_unix(datetime, :second)}
  end

  def dump(_), do: :error
end
