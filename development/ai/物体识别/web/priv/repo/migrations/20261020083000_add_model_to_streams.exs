defmodule Web.Repo.Migrations.AddModelToStreams do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :model, :string, default: "industry", null: false
    end
  end
end
