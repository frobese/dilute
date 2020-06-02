defmodule Dilute.Adapter.Struct do
  @moduledoc false
  use Dilute.Adapter

  @impl Dilute.Adapter
  def applicable?(module) do
    function_exported?(module, :types, 0)
  rescue
    FunctionClauseError -> false
  end

  @impl Dilute.Adapter
  def fields(module) do
    for {field, type} <- module.types() do
      {card, mapped_type, type} = map_type(type)

      {field, card, mapped_type, type}
    end
  end

  def map_type([type]) when not is_list(type) do
    {_card, mapped_type, type} = map_type(type)

    {:many, mapped_type, type}
  end

  def map_type(type) do
    if applicable?(type) do
      {:one, :"$module", type}
    else
      {:one, Dilute.Adapter.Ecto.map_type(type), type}
    end
  end
end
