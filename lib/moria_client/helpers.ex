defmodule MoriaClient.Helpers do
  @moduledoc false
  alias MoriaClient.Errors

  @doc """
  Convert a map or other data structure into an Ecto schema by applying the schema's changeset function
  """
  def to_schema(data, schema) when is_atom(schema) do
    data
    |> schema.changeset()
    |> Ecto.Changeset.apply_action(:validate_server_response)
  end

  def flatten_query_pairs({key, value})
      when is_binary(value) or is_number(value) or is_boolean(value) or is_atom(value) do
    [{to_string(key), to_string(value)}]
  end

  def flatten_query_pairs({key, value}) when is_map(value) do
    Enum.flat_map(value, fn {k, v} -> flatten_query_pairs({"#{key}[#{k}]", v}) end)
  end

  def flatten_query_pairs({key, []}) do
    # empty list values becomes key[]= because flop handles this on the server side
    [{"#{key}[]", ""}]
  end

  def flatten_query_pairs({key, value}) when is_list(value) do
    Enum.flat_map(Enum.with_index(value), fn {item, index} ->
      suffix = if is_map(item) or is_list(item), do: "[#{index}]", else: "[]"
      flatten_query_pairs({"#{key}#{suffix}", item})
    end)
  end

  def to_query(opts) do
    # detect duplicate (outer)keys and raise
    keys = Enum.map(opts, fn {k, _v} -> k end)
    uniq_keys = Enum.uniq(keys)
    duplicate_keys = Enum.uniq(keys -- uniq_keys)

    if duplicate_keys != [] do
      raise ArgumentError, "Duplicate query keys in #{inspect(duplicate_keys)}"
    end

    opts
    |> Enum.flat_map(&flatten_query_pairs/1)
    |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  def handle_common_errors(%{status: 400} = env),
    do: {:error, Errors.BadRequest.from_env!(env)}

  def handle_common_errors(%{status: 404} = env),
    do: {:error, Errors.NotFound.from_env!(env)}

  def handle_common_errors(%{status: 500} = env),
    do: {:error, Errors.InternalServerError.from_env!(env)}

  def handle_common_errors(%{status: 401} = env),
    do: {:error, Errors.Unauthorized.from_env!(env)}

  def handle_common_errors(%{status: 409} = env),
    do: {:error, Errors.Conflict.from_env!(env)}

  def handle_common_errors(%{status: 422} = env),
    do: {:error, Errors.Unprocessable.from_env!(env)}

  @doc """
  Stream paginated results from a page function that returns {:ok, page} tuples.

  This can be used with any function that takes a single opts argument and
  returns paginated results in the form of {:ok, page},
  where `page` contains a `page` map with `end_cursor` and `has_next_page` fields.

  This is commonly done with listing functions by `&MoriaClient.list_<resource>(client, &1)`.

  NOTE: This function throws `{:error, reason}` if it encounters an error from the page function.

  NOTE: This only works with forward pagination (using `after` cursors and `first` limits).
  """
  def stream_pages(page_fun, opts) do
    if not Keyword.has_key?(opts, :first) do
      raise ArgumentError, "stream_pages/2 requires :first option to be set for pagination"
    end

    Stream.unfold(nil, fn
      :halt ->
        nil

      cursor ->
        pagination = if(cursor, do: [after: cursor], else: [])

        case page_fun.(Keyword.merge(opts, pagination)) do
          {:ok, %{page: %{end_cursor: next_cursor, has_next_page: has_next_page}} = page} ->
            next_cursor =
              if has_next_page do
                next_cursor
              else
                :halt
              end

            if has_next_page and is_nil(next_cursor) do
              raise """
              Pagination error: next_cursor is nil, but has_next_page is true.
              This may indicate a bug in the client or server.
              """
            end

            if has_next_page and next_cursor == cursor do
              raise """
              Pagination error: next_cursor is the same as the previous cursor (#{inspect(cursor)}).
              This may indicate a bug in the client or server.
              """
            end

            {page, next_cursor}

          {:error, reason} ->
            throw({:error, reason})
        end
    end)
  end
end
