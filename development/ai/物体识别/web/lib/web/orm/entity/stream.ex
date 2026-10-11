defmodule Web.Orm.Entity.Stream do
  use Ecto.Schema
  import Ecto.Changeset

  schema "streams" do
    field(:stream_id, :string)
    field(:title, :string)
    field(:rtsp_url, :string)
    field(:enabled, :boolean, default: true)
    field(:position, :integer, default: 0)
    field(:zone_config, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(stream, attrs) do
    stream
    |> cast(attrs, [:stream_id, :title, :rtsp_url, :enabled, :position, :zone_config])
    |> validate_required([:stream_id, :rtsp_url])
    |> validate_format(:stream_id, ~r/^[a-zA-Z0-9_\-]+$/, message: "只允许字母、数字、下划线和短横线")
    |> unique_constraint(:stream_id)
  end
end
