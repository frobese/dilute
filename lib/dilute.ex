defmodule Dilute do
  @moduledoc """
  `Ecto.Schema` are very similar to `Absinthe.Type.Object` definitions and are required to be kept in sync.
  Dilute is able to derive Absinthe objects and their relations based on `Ecto.Schema` definitions and offers the ability to translate query resolutions into efficient SQL statements.

  ## Types
  Absinthe objects placed inside your `Types` module:

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation
        import Dilute
        alias MyApp.Blog.{Post, Comment}

        ecto_object(Post)

        ecto_object(Comment)
      end

  ## Resolution
  The resolver can be defined with:

      defmodule MyAppWeb.Resolver do
        use Dilute.Resolver, types: MyAppWeb.Schema.Types, repo: MyApp.Repo
      end

  Queries can either be defined using the `resolve/3` function ...

      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        alias MyAppWeb.{Resolver, Schema}
        import_types(Schema.Types)

        query do
          @desc "Get one Post"
          field :post, :post do
            resolve(&Resolver.resolve/3)
          end
        end
      end

  ... or the `query_fields/2` macro.

      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        alias MyAppWeb.{Resolver, Schema}
        import_types(Schema.Types)

        query do
          MyWebApp.Schema.query_fields(:post, &Resolver.resolve/3)
        end
      end

  """

  @doc """
  Defines an Absinthe object based on the ecto schema of the given module.

  Settings the `:associations` option to `false` will omit the associations in the definition.
  Fields can be excluded using the `:exclude` option.

      ecto_object Post, exclude: :id do
      end

  Additionally the do block will override any field definitions.

      ecto_object Post do
        field(:rating, :float)
      end

  Ecto allows for Custom Type definitions which have to be overwritten.
  """
  @default_ecto_object [associations: true, exclude: []]
  @default_ecto_input_object [associations: true, exclude: [], prefix: true]
  @input_prefix "input_"

  defmacro ecto_object(module) do
    quote do
      Dilute.ecto_object(unquote(module), [], do: [])
    end
  end

  defmacro ecto_object(module, do: block) do
    quote do
      Dilute.ecto_object(unquote(module), [], do: unquote(block))
    end
  end

  defmacro ecto_object(module, opts) do
    quote do
      Dilute.ecto_object(unquote(module), unquote(opts), do: [])
    end
  end

  defmacro ecto_object(module, opts, do: block) do
    module = Macro.expand(module, __CALLER__)
    ecto_check(module)

    opts =
      Keyword.merge(@default_ecto_object, opts)
      |> update_in([:exclude], &List.wrap/1)

    overrides = overrides(block)
    expanded_exlcudes = opts[:exclude] ++ overrides

    warnings(__CALLER__, module, opts[:exclude])

    {schema, schema_plural} = schema_tuple(module)

    fields = fields(module, expanded_exlcudes, "")
    assocs = associations(module, expanded_exlcudes)

    joins =
      assocs
      |> Enum.reduce([], fn {field, assoc, _, _}, acc ->
        case assoc do
          %Ecto.Association.BelongsTo{} -> [field | acc]
          %Ecto.Association.Has{} -> [field | acc]
          _ -> acc
        end
      end)

    quote do
      def __object__(:module, unquote(schema)), do: unquote(module)
      def __object__(:schema, unquote(module)), do: unquote(schema)
      def __object__(:joins, unquote(schema)), do: unquote(joins)
      # def __object__(:exclude, unquote(schema)), do: unquote(opts[:exclude])

      # defmacro query_fields(unquote(module), resolver) do
      #   schema = unquote(schema)

      #   quote do
      #     querry_fields(unquote(schema), unquote(resolver))
      #   end
      # end

      defmacro query_fields(unquote(schema), resolver) do
        fields = unquote(fields)

        schema = unquote(schema)
        schema_plural = unquote(schema_plural)

        quote do
          field unquote(schema), unquote(schema) do
            unquote(Dilute.args(fields))

            resolve(unquote(resolver))
          end

          field unquote(schema_plural), list_of(unquote(schema)) do
            unquote(
              for {field, type} <- fields do
                if is_atom(type) do
                  quote do
                    arg(unquote(field), unquote(type))
                  end
                end
              end
            )

            resolve(unquote(resolver))
          end
        end
      end

      object unquote(schema) do
        unquote(
          [
            quote do
              Macro.expand_once(unquote(block), unquote(__CALLER__))
            end
            | for {field, type} <- fields do
                case type do
                  {:one, schema} ->
                    quote do
                      field(unquote(field), unquote(schema))
                    end

                  {:many, schema} ->
                    quote do
                      field(unquote(field), list_of(unquote(schema)))
                    end

                  type ->
                    quote do
                      field(unquote(field), unquote(type))
                    end
                end
              end
          ] ++
            if opts[:associations] do
              for {field, assoc, schema, fields} <- assocs do
                case assoc do
                  %Ecto.Association.BelongsTo{} ->
                    quote do
                      field(unquote(field), unquote(schema)) do
                        unquote(Dilute.args(fields))
                      end
                    end

                  %Ecto.Association.Has{} ->
                    quote do
                      field(unquote(field), list_of(unquote(schema))) do
                        unquote(Dilute.args(fields))
                      end
                    end

                  _ ->
                    raise "Dilute is currently only implemented for Ecto's BelongsTo and Has associations"
                end
              end
            else
              []
            end
        )
      end
    end
  end

  defmacro ecto_input_object(module) do
    quote do
      Dilute.ecto_input_object(unquote(module), [], do: [])
    end
  end

  defmacro ecto_input_object(module, do: block) do
    quote do
      Dilute.ecto_input_object(unquote(module), [], do: unquote(block))
    end
  end

  defmacro ecto_input_object(module, opts) do
    quote do
      Dilute.ecto_input_object(unquote(module), unquote(opts), do: [])
    end
  end

  defmacro ecto_input_object(module, opts, do: block) do
    module = Macro.expand(module, __CALLER__)
    ecto_check(module)

    opts =
      Keyword.merge(@default_ecto_input_object, opts)
      |> update_in([:exclude], &List.wrap/1)

    overrides = overrides(block)
    expanded_exlcudes = opts[:exclude] ++ overrides

    warnings(__CALLER__, module, opts[:exclude])

    {schema, _schema_plural} =
      if opts[:prefix] do
        schema_tuple(module, @input_prefix)
      else
        schema_tuple(module)
      end

    fields = fields(module, expanded_exlcudes, @input_prefix)
    assocs = associations(module, expanded_exlcudes)

    quote do
      # def __input_object__(:module, unquote(schema)), do: unquote(module)
      # def __input_object__(:schema, unquote(module)), do: unquote(schema)

      input_object unquote(schema) do
        unquote(
          [
            quote do
              Macro.expand_once(unquote(block), unquote(__CALLER__))
            end
            | for {field, type} <- fields do
                case type do
                  {:one, schema} ->
                    quote do
                      field(unquote(field), unquote(schema))
                    end

                  {:many, schema} ->
                    quote do
                      field(unquote(field), list_of(unquote(schema)))
                    end

                  type ->
                    quote do
                      field(unquote(field), unquote(type))
                    end
                end
              end
          ] ++
            if opts[:associations] do
              for {field, assoc, schema, fields} <- assocs do
                case assoc do
                  %Ecto.Association.BelongsTo{} ->
                    quote do
                      field(unquote(field), unquote(schema)) do
                        unquote(Dilute.args(fields))
                      end
                    end

                  %Ecto.Association.Has{} ->
                    quote do
                      field(unquote(field), list_of(unquote(schema))) do
                        unquote(Dilute.args(fields))
                      end
                    end

                  _ ->
                    raise "Dilute is currently only implemented for Ecto's BelongsTo and Has associations"
                end
              end
            else
              []
            end
        )
      end
    end
  end

  defp warnings(%{file: file, line: line}, module, excludes) do
    identifiers = module.__schema__(:fields) ++ module.__schema__(:associations)

    for exclude <- excludes do
      if exclude not in identifiers do
        IO.warn(
          [
            "Excluding ",
            inspect(exclude),
            " wich is not present as a field in ",
            inspect(module)
          ],
          [{__MODULE__, :__MODULE__, 1, [file: to_charlist(file), line: line]}]
        )
      end
    end
  end

  @spec schema_tuple(module(), String.t()) :: {singular :: atom(), plural :: atom()}
  defp schema_tuple(module, prefix \\ "") when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> (fn schema -> prefix <> schema end).()
    |> (fn schema -> [schema, schema <> "s"] end).()
    |> Enum.map(&String.to_atom/1)
    |> List.to_tuple()
  end

  defp ecto_check(module) do
    cond do
      not Code.ensure_compiled?(module) ->
        raise "referenced module #{inspect(module)} could not be complied/loaded"

      not function_exported?(module, :__schema__, 2) ->
        raise "referenced module #{inspect(module)} is not an Ecto schema"

      true ->
        :ok
    end
  end

  defp exclude(lst, []) do
    lst
  end

  defp exclude(lst, [h | t]) do
    lst
    |> List.delete(h)
    |> exclude(t)
  end

  @doc false
  def args(fields) do
    for {field, type} <- fields do
      quote do
        arg(unquote(field), unquote(type))
      end
    end
  end

  # returns the field definition for a given module
  defp fields(module, exclude, prefix \\ "") do
    import Dilute.Mapper

    module.__schema__(:fields)
    |> exclude(exclude)
    |> Enum.map(fn field ->
      type =
        case module.__schema__(:type, field) do
          {:embed, %Ecto.Embedded{related: related, cardinality: cardinality}} ->
            {schema, _schema_plural} = schema_tuple(related, prefix)

            {cardinality, schema}

          {:array, type} ->
            {:many, map(type)}

          type ->
            map(type)
        end

      {field, type}
    end)
  end

  # returns all associations for a given module
  defp associations(module, exclude) do
    module.__schema__(:associations)
    |> exclude(exclude)
    |> Enum.map(fn field ->
      assoc = %{related: mod} = module.__schema__(:association, field)

      {schema, _schema_plural} = schema_tuple(mod)

      fields = fields(mod, [])

      {field, assoc, schema, fields}
    end)
  end

  defp overrides([]) do
    []
  end

  defp overrides({:__block__, _, block}) do
    overrides(block)
  end

  defp overrides({:field, _, [field | _]}) do
    [field]
  end

  defp overrides([{:field, _, [field | _]} | rest]) do
    [field | overrides(rest)]
  end

  defp overrides([_ | rest]) do
    overrides(rest)
  end
end
