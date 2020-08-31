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

        dilute_object(Post)

        dilute_object(Comment)
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

      dilute_object Post, exclude: :id do
      end

  Additionally the do block will override any field definitions.

      dilute_object Post do
        field(:rating, :float)
      end

  Ecto allows for Custom Type definitions which have to be overwritten.
  """
  @adapters [Dilute.Adapter.Ecto, Dilute.Adapter.Struct]
  @default_dilute_object [associations: true, exclude: []]
  @default_dilute_input_object [associations: true, exclude: [], prefix: true]
  @input_prefix "input_"

  alias Dilute.Env

  defmacro dilute_object(module) do
    quote do
      Dilute.dilute_object(unquote(module), [], do: [])
    end
  end

  defmacro dilute_object(module, do: block) do
    quote do
      Dilute.dilute_object(unquote(module), [], do: unquote(block))
    end
  end

  defmacro dilute_object(module, opts) do
    quote do
      Dilute.dilute_object(unquote(module), unquote(opts), do: [])
    end
  end

  defmacro dilute_object(module, opts, block) do
    with module <- Macro.expand(module, __CALLER__),
         {:module, _module} <- Code.ensure_compiled(module) do
      quote do
        Dilute.__dilute_object__(unquote(module), unquote(opts), unquote(block))
      end
    else
      {:error, error} ->
        IO.warn(
          "Module could not be compiled, reason: #{error}",
          Macro.Env.stacktrace(__CALLER__)
        )
    end
  end

  defmacro __dilute_object__(module, opts, do: block) do
    opts = Keyword.merge(@default_dilute_object, opts)

    env =
      module
      |> Env.init(__CALLER__)
      |> Env.excludes(opts[:exclude])
      |> Env.overwrites(block)
      |> Env.schema_identifier()
      |> Env.adapter(@adapters)

    fields =
      env
      |> Env.fields()
      |> resolve_modules()

    quote do
      def __object__(:module, unquote(env.schema)), do: unquote(module)

      object unquote(env.schema) do
        unquote([
          quote do
            Macro.expand_once(unquote(block), unquote(__CALLER__))
          end
          | for field <- fields do
              case field do
                {field, :one, type, _related} ->
                  quote do
                    field(unquote(field), unquote(type))
                  end

                {field, :many, type, _related} ->
                  quote do
                    field(unquote(field), list_of(unquote(type)))
                  end
              end
            end
        ])
      end
    end
  end

  defmacro dilute_input_object(module) do
    quote do
      Dilute.dilute_input_object(unquote(module), [], do: [])
    end
  end

  defmacro dilute_input_object(module, do: block) do
    quote do
      Dilute.dilute_input_object(unquote(module), [], do: unquote(block))
    end
  end

  defmacro dilute_input_object(module, opts) do
    quote do
      Dilute.dilute_input_object(unquote(module), unquote(opts), do: [])
    end
  end

  defmacro dilute_input_object(module, opts, block) do
    with module <- Macro.expand(module, __CALLER__),
         {:module, _module} <- Code.ensure_compiled(module) do
      quote do
        Dilute.__dilute_input_object__(unquote(module), unquote(opts), unquote(block))
      end
    else
      {:error, error} ->
        IO.warn(
          "Module could not be compiled, reason: #{error}",
          Macro.Env.stacktrace(__CALLER__)
        )
    end
  end

  defmacro __dilute_input_object__(module, opts, do: block) do
    opts = Keyword.merge(@default_dilute_input_object, opts)

    env =
      module
      |> Env.init(__CALLER__)
      |> Env.excludes(opts[:exclude])
      |> Env.overwrites(block)
      |> Env.schema_identifier(if opts[:prefix], do: @input_prefix, else: "")
      |> Env.adapter(@adapters)

    fields =
      env
      |> Env.fields()
      |> resolve_modules(@input_prefix)

    quote do
      input_object unquote(env.schema) do
        unquote([
          quote do
            Macro.expand_once(unquote(block), unquote(__CALLER__))
          end
          | for field <- fields do
              case field do
                {field, :one, type, _related} ->
                  quote do
                    field(unquote(field), unquote(type))
                  end

                {field, :many, type, _related} ->
                  quote do
                    field(unquote(field), list_of(unquote(type)))
                  end
              end
            end
        ])
      end
    end
  end

  ######
  #
  #  Helper
  #

  # defp schema_tuple(module, prefix \\ "") when is_atom(module) do
  #   module
  #   |> Module.split()
  #   |> List.last()
  #   |> Macro.underscore()
  #   |> (fn schema -> prefix <> schema end).()
  #   |> (fn schema -> [schema, schema <> "s"] end).()
  #   |> Enum.map(&String.to_atom/1)
  #   |> List.to_tuple()
  # end

  def schema_identifier(module, prefix) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.replace_prefix("", prefix)
    |> String.to_atom()
  end

  def resolve_modules(fields, prefix \\ "") do
    Enum.map(fields, fn field ->
      case field do
        {field, cardinality, :"$module", related} ->
          {field, cardinality, schema_identifier(related, prefix), related}

        field ->
          field
      end
    end)
  end
end
