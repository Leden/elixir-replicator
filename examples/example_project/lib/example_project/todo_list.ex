defmodule ExampleProject.TodoList do
  use Ecto.Schema

  import Ecto.Changeset

  schema "todo_list" do
    field :name, :string
    timestamps()
  end

  def changeset(todo_list, params \\ %{}) do
    todo_list
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
