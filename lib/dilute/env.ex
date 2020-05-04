defmodule Dilute.Env do
  @moduledoc false
  defstruct [
    :adapter,
    :error,
    :module,
    :schema_env,
    # :schema_plural,
    :schema,
    excludes: [],
    overwrites: []
  ]

  def init(module, %Macro.Env{} = caller) do
    %__MODULE__{
      schema_env: caller,
      module: module
    }
  end

  def excludes(%__MODULE__{} = env, excludes) do
    %__MODULE__{env | excludes: List.wrap(excludes)}
  end

  def overwrites(%__MODULE__{} = env, block) do
    overwrites = __overwrites__(block)

    [{module, name, arity, relative_location}] = Macro.Env.stacktrace(env.schema_env)

    for {field, location} <- overwrites do
      if field in env.excludes do
        IO.warn(
          "Overrides automatically exclude the field from the source schema, remove #{field} from the excludes",
          [{module, name, arity, Keyword.merge(relative_location, location)}]
        )
      end
    end

    %__MODULE__{env | overwrites: overwrites}
  end

  def __overwrites__({:__block__, _, block}) do
    __overwrites__(block)
  end

  def __overwrites__({:field, location, [field | _]}) do
    [{field, location}]
  end

  def __overwrites__([{:field, location, [field | _]} | rest]) do
    [{field, location} | __overwrites__(rest)]
  end

  def __overwrites__([_ | rest]) do
    __overwrites__(rest)
  end

  def __overwrites__([]) do
    []
  end

  def schema_identifier(%__MODULE__{module: module} = env, prefix \\ "") do
    %__MODULE__{env | schema: Dilute.schema_identifier(module, prefix)}
  end

  def adapter(%__MODULE__{module: module} = env, adapters) do
    applicable =
      Enum.filter(adapters, fn adapter ->
        adapter.applicable?(module)
      end)

    case applicable do
      [adapter] ->
        %__MODULE__{env | adapter: adapter}

      [] ->
        raise Dilute.SchemaError, "No applicable adapter found for #{module}"

      [_ | _] ->
        raise Dilute.SchemaError, "Multiple applicable adapter found for #{module}"
    end
  end

  def fields(%__MODULE__{adapter: adapter, module: module} = env) do
    module
    |> adapter.fields()
    |> filter_excludes(env)
    |> filter_overwrites(env)
  end

  defp filter_excludes(fields, %__MODULE__{} = env) do
    {fields, futile_excludes} =
      Enum.map_reduce(fields, env.excludes, fn {indentifier, _, _, _} = field, excludes ->
        if indentifier in excludes do
          {nil, List.delete(excludes, indentifier)}
        else
          {field, excludes}
        end
      end)

    for exclude <- futile_excludes do
      IO.warn("#{exclude} is not a field of #{env.module}", Macro.Env.stacktrace(env.schema_env))
    end

    Enum.reject(fields, &is_nil/1)
  end

  defp filter_overwrites(fields, %__MODULE__{overwrites: overwrites}) do
    locationless_overwrites = Enum.map(overwrites, &elem(&1, 0))

    Enum.reject(fields, fn {indentifier, _, _, _} ->
      indentifier in locationless_overwrites
    end)
  end
end
