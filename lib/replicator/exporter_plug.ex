defmodule Replicator.ExporterPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    path = opts[:path]

    case conn.request_path do
      ^path -> send_replogs(conn)

      _ -> conn
    end
  end

  defp send_replogs(conn) do
    conn = conn |> fetch_query_params()

    {_, data} = result = prepare_replogs(conn.query_params["last_id"])

    code = case result do
      {:ok, _} -> 200
      {:error, _} -> 400
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, data |> Poison.encode!())
    |> halt
  end

  defp prepare_replogs(last_id) do
    case last_id do
      nil -> 0
      last_id -> String.to_integer(last_id)
    end
    |> Replicator.get_replog()
    |> Enum.map(fn %module{} = replog ->
         replog |> Map.from_struct() |> Map.take(module.__schema__(:fields))
       end)
    |> case do
        [] -> {:error, %{error: "No data at this ID", details: %{last_id: last_id}}}
        replogs -> {:ok, replogs}
       end
  end
end
