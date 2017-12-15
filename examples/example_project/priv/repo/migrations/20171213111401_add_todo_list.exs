defmodule ExampleProject.Repo.Migrations.AddTodoList do
  use Ecto.Migration

  def change do
    create table("todo_list") do
      add :name, :string
      timestamps()
    end
  end
end
