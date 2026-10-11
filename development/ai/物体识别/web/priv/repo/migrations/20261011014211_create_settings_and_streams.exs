defmodule Web.Repo.Migrations.CreateSettingsAndStreams do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :key, :string, null: false
      add :value, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:settings, [:key])

    create table(:streams) do
      add :stream_id, :string, null: false
      add :title, :string
      add :rtsp_url, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :position, :integer, default: 0
      add :zone_config, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:streams, [:stream_id])
  end
end
