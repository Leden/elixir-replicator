defmodule ExampleProject.Repo.Migrations.AddTodoItem do
  use Ecto.Migration

  def change do
    create table("todo_item") do
      add :text, :string
      add :is_done, :boolean, default: false
      add :list_id, references("todo_list")
      timestamps()
    end
  end
end
