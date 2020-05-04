defmodule Dilute.AdapterError do
  @moduledoc """
  Raised during compiletime should an adapter run into unresolvable errors
  """
  defexception [:message]
end

defmodule Dilute.SchemaError do
  @moduledoc """
  Raised during compiletime for unrecveralbe errors in the schema
  """
  defexception [:message]
end
