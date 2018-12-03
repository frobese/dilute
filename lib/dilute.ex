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

        ecto_object Post do
        end

        ecto_object Comment do
        end
      end

  ## Resolution
  The resolver can be defined as:

      defmodule MyAppWeb.Resolver do
        use Dilute.Resolver, types: MyAppWeb.Schema.Types, repo: MyApp.Repo
      end

  Queries can either be defined using the `resolve/3` function ...

      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        import_types(MyAppWeb.Schema.Types)

        query do
          @desc "Get one Post"
          field :post, :post do
              resolve(&MyAppWeb.Resolver.resolve/3)
          end
        end
      end

  ... or the `query_fields/2` macro.

      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        import_types(MyAppWeb.Schema.Types)

        alias BlogWeb.Resolvers

        query do
          MyWebApp.Schema.query_fields(:post, &Resolver.resolve/3)
        end
      end

  """

  @doc """
  Defines an Absinthe object based on the ecto schema of the given module.

  Settings the `:associations` option to `false` will omit the associations in the definition.
  Fields can be excluded using the `:exclude` option.

      ecto_object User, exclude: [:email, :forename], associations: false do
      end

  Additionally the do block will override any field definitions.

      ecto_object Post do
        field(:title, :string)
      end
  """
  @default_opts [associations: true, exclude: []]
  defmacro ecto_object(module, opts \\ [], do: block) do
    module = Macro.expand(module, __CALLER__)

    opts =
      Keyword.merge(@default_opts, opts)
      |> update_in([:exclude], &List.wrap/1)

    ecto_check(module)

    {schema, schema_plural} = schema_tuple(module)

    fields = fields(module, opts[:exclude])

    assocs =
      module.__schema__(:associations)
      |> exclude(opts[:exclude])
      |> Enum.map(fn field ->
        assoc = %{related: mod} = module.__schema__(:association, field)

        {schema, _schema_plural} = schema_tuple(mod)

        fields = fields(mod, [])

        {field, assoc, schema, fields}
      end)

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
      def __object__(:schema, unquote(schema)), do: unquote(module)
      def __object__(:joins, unquote(schema)), do: unquote(joins)
      # def __object__(:exclude, unquote(schema)), do: unquote(opts[:exclude])

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
                quote do
                  arg(unquote(field), unquote(type))
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
                quote do
                  field(unquote(field), unquote(type))
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

  defp schema_tuple(module) when is_atom(module) do
    # {schema, schema_plural} =
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
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

  defp fields(module, exclude) do
    module.__schema__(:fields)
    |> exclude(exclude)
    |> Enum.map(fn field ->
      type = Dilute.Mapper.map(module.__schema__(:type, field))
      {field, type}
    end)
  end
end
