defmodule ExampleProject.Router do
  use Plug.Router
  use Plug.ErrorHandler

  alias ExampleProject.TodoList
  alias ExampleProject.TodoItem
  alias ExampleProject.Repo

  import Replicator

  plug :match
  plug Plug.Logger, log: :debug
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :dispatch

  ### To_do Lists ###

  get "/lists" do
    TodoList
    |> Repo.all()
    |> Enum.map(&to_plain_map/1)
    |> response(200, conn)
  end

  post "/lists" do
    %TodoList{}
    |> TodoList.changeset(conn.params)
    |> Repo.insert()
    |> case do
         {:ok, todo_list} ->
           log_insert(todo_list)
           todo_list |> to_plain_map() |> response(201, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  get "/lists/:id" do
    TodoList
    |> Repo.get!(conn.params["id"])
    |> to_plain_map()
    |> response(200, conn)
  end

  post "/lists/:id" do
    previous_todo_list = Repo.get!(TodoList, conn.params["id"])

    previous_todo_list
    |> TodoList.changeset(conn.params)
    |> Repo.update()
    |> case do
         {:ok, current_todo_list} ->
           log_update(previous_todo_list, current_todo_list)
           current_todo_list |> to_plain_map() |> response(201, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  delete "/lists/:id" do
    TodoList
    |> Repo.get!(conn.params["id"])
    |> Repo.delete()
    |> case do
         {:ok, todo_list} ->
           log_delete(todo_list)
           response("", 204, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  ### To_do items ###

  get "/items" do
    TodoItem
    |> Repo.all()
    |> Enum.map(&to_plain_map/1)
    |> response(200, conn)
  end

  post "/items" do
    %TodoItem{}
    |> TodoItem.changeset(conn.params)
    |> Repo.insert()
    |> case do
         {:ok, todo_item} ->
           log_insert(todo_item)
           todo_item |> to_plain_map() |> response(201, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  get "/items/:id" do
    TodoItem
    |> Repo.get!(conn.params["id"])
    |> to_plain_map()
    |> response(200, conn)
  end

  post "/items/:id" do
    previous_todo_item = Repo.get!(TodoItem, conn.params["id"])

    previous_todo_item
    |> TodoItem.changeset(conn.params)
    |> Repo.update()
    |> case do
         {:ok, current_todo_item} ->
           log_update(previous_todo_item, current_todo_item)
           current_todo_item |> to_plain_map() |> response(201, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  delete "/items/:id" do
    TodoItem
    |> Repo.get!(conn.params["id"])
    |> Repo.delete()
    |> case do
         {:ok, todo_item} ->
           log_delete(todo_item)
           response("", 204, conn)

         {:error, changeset} ->
           changeset |> error_messages() |> response(400, conn)
       end
  end

  ### Replicator sync api handle ###

  get "/replog" do
    last_id = case conn.params["last_id"] do
      nil -> 0
      last_id -> String.to_integer(last_id)
    end

    get_replog(last_id)
    |> Enum.map(&to_plain_map/1)
    |> response(200, conn)
  end

  ### Catch-all 404 handler ###

  match _ do
    response(%{error: "Not found"}, 404, conn)
  end

  ### Error handler ###

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    response(inspect(reason), 500, conn)
  end

  defp response(data, code, conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, data |> Poison.encode!())
  end

  defp to_plain_map(%module{} = schema),
    do: schema |> Map.from_struct() |> Map.take(module.__schema__(:fields))

  defp error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end