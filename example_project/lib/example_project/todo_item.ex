defmodule ExampleProject.TodoItem do
  use Ecto.Schema

  import Ecto.Changeset

  schema "todo_item" do
    field :text, :string
    field :is_done, :boolean, default: false
    belongs_to :list, ExampleProject.TodoList
    timestamps()
  end

  def changeset(todo_item, params \\ %{}) do
    todo_item
    |> cast(params, [:text, :is_done, :list_id])
    |> validate_required([:text, :is_done, :list_id])
  end
end
