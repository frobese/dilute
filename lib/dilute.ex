defmodule Dilute do
  @moduledoc """
  `Ecto.Schema` are very similar to `Absinthe.Type.Object` definitions and are required to be kept in sync.
  Dilute is able to derive `Absinthe.Type.Object` on their relations based on `Ecto.Schema` definitions.

  ## Types
  Absinthe objects placed inside your `Types` module:

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation
        require Dilute
        alias MyApp.Blog.{Post, Comment}

        Dilute.object(Post)
        Dilute.object(Comment)
      end

  ## Resolution
  The resolver can be defined as:

      defmodule MyAppWeb.Resolver do
        use Dilute.Resolver, types: MyAppWeb.Schema.Types, repo: MyApp.Repo
      end

  Queries can either be defined using the `resolve/3` function or the `query_fields/2` macro


      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        import_types(MyAppWeb.Schema.Types)

        query do
          @desc "Get one Post"
          field :post, :post do
              resolve(&MyAppWeb.Resolver.resolve/3)
          end


      defmodule MyAppWeb.Schema do
        use Absinthe.Schema
        import_types(MyAppWeb.Schema.Types)

        alias BlogWeb.Resolvers

        query do
          @desc "Get one Post"
          field :post, :post do
              resolve(&MyAppWeb.Resolver.resolve/3)
          end

          @desc "Get all Posts"
          field :posts, list_of(:post) do
            resolve(&MyAppWeb.Resolver.resolve/3)
          end

          query do
            MyWebApp.Schema.query_fields(:post, &Resolver.resolve/3)
          end
        end
      end

  """
  import Absinthe.Schema.Notation
  require Dilute.Query

  defmacro __using__(_) do
    IO.puts("Register exclude for caller")

    quote do
      Module.register_attribute(__MODULE__, :exclude, accumulate: false, persist: true)
    end
  end

  @doc """
  Defines an Absinthe object based on the ecto schema of the given module.

  Fields can be excluded by including the respective field in the `@exclude` attribute:

      @exclude [
        # ...
        {User, [:email, :forename]}
        # ...
      ]

      Dilute.object(User)
  """
  @default_opts [associations: true, exclude: []]
  defmacro ecto_object(module, opts \\ [], do: block) do
    module = Macro.expand(module, __CALLER__)
    opts = Keyword.merge(@default_opts, opts)

    ecto_check(module)

    env = __CALLER__

    # module.__schema__(:source)
    {schema, schema_plural} = schema_tuple(module)

    # # Module.register_attribute(__CALLER__.module, :exclude, accumulate: true)
    # exclude = Module.get_attribute(__CALLER__.module, :exclude) || []

    # exclude
    # |> IO.inspect(label: "exclude", limit: 30000)

    # fields = fields(module, Keyword.get(exclude, module, []))
    fields = fields(module, opts[:exclude])

    assocs =
      module.__schema__(:associations)
      # |> exclude(exclude)
      |> Enum.map(fn field ->
        assoc = %{related: mod} = module.__schema__(:association, field)

        {schema, _schema_plural} = schema_tuple(mod)

        # fields = fields(mod, Keyword.get(exclude, mod, []))
        fields = fields(mod, [])

        {field, assoc, schema, fields}
      end)

    quote do
      def __object__(:schema, unquote(schema)), do: unquote(module)
      # def __object__(:exclude, unquote(schema)), do: unquote(opts[:exclude])

      defmacro query_fields(unquote(schema), resolver) do
        exclude = unquote(opts[:exclude])

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
              Macro.expand_once(unquote(block), unquote(env))
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
    |> String.downcase()
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
