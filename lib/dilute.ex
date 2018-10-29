defmodule Dilute do
  @moduledoc """
  Absinthe objects can be defined inside your `Types` module:

      defmodule MyAppWeb.Schema.Types do
        use Absinthe.Schema.Notation
        require Dilute
        alias MyApp.Blog.{Post, Comment}

        Dilute.object(Post)
        Dilute.object(Comment)
      end

  Once the types are defined the resolver can be defined as:

      defmodule MyAppWeb.Resolver do
        user Dilute.Resolver, types: MyAppWeb.Schema.Types, repo: MyApp.Repo
      end

  Querys can either be defined using the `resolve/3` function or user the `query_fields/2` macro

    query do
      @desc "Get all Posts"
      field :posts, list_of(:post) do
        resolve(&MyAppWeb.Resolver.resolve/3)
      end

      query do
        MyWebApp.Schema.query_fields(:post, &Resolver.resolve/3)
      end
    end
  """
  import Absinthe.Schema.Notation
  require Dilute.Query

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
  defmacro object(module) do
    module = Macro.expand(module, __CALLER__)
    # opts = Keyword.merge(@defaults, opts)

    cond do
      not Code.ensure_compiled?(module) ->
        raise "referenced module #{inspect(module)} could not be complied/loaded"

      not function_exported?(module, :__schema__, 2) ->
        raise "referenced module #{inspect(module)} is not an Ecto schema"

      true ->
        :ok
    end

    schema =
      module.__schema__(:source)
      |> String.downcase()
      |> String.to_atom()

    schema_plural =
      module.__schema__(:source)
      |> String.downcase()
      |> (fn schema -> schema <> "s" end).()
      |> String.to_atom()

    excludes = Module.get_attribute(__CALLER__.module, :excludes) || []

    fields = fields(module, Keyword.get(excludes, module, []))

    assocs =
      module.__schema__(:associations)
      |> exclude(excludes)
      |> Enum.map(fn field ->
        assoc = %{related: mod} = module.__schema__(:association, field)

        schema =
          mod.__schema__(:source)
          |> String.downcase()
          |> String.to_atom()

        fields = fields(mod, Keyword.get(excludes, mod, []))

        {field, assoc, schema, fields}
      end)

    quote do
      def __object__(:schema, unquote(schema)), do: unquote(module)

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
          for {field, type} <- fields do
            quote do
              field(unquote(field), unquote(type))
            end
          end ++
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
        )
      end
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

  def args(fields) do
    for {field, type} <- fields do
      quote do
        arg(unquote(field), unquote(type))
      end
    end
  end

  defp fields(module, exclude \\ []) do
    module.__schema__(:fields)
    |> exclude(exclude)
    |> Enum.map(fn field ->
      {field, module.__schema__(:type, field)}
    end)
  end
end
