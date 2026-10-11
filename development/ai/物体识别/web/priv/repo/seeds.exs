alias Web.Repo
alias Web.Orm.Query.Settings
alias Web.Orm.Entity.Stream

if is_nil(Settings.get_setting("gateway_url")) do
  Settings.set_gateway_url("http://192.168.88.100:8181")
end

if is_nil(Settings.get_setting("alert_callback_url")) do
  Settings.set_alert_callback_url("http://192.168.88.20:4000/api/alert")
end

if is_nil(Settings.get_setting("alert_cooldown_sec")) do
  Settings.set_alert_cooldown_sec("1")
end

if is_nil(Settings.get_setting("alert_timeout_sec")) do
  Settings.set_alert_timeout_sec("3")
end

initial_streams = [
  %{
    stream_id: "aaa",
    title: "通道 1: aaa",
    rtsp_url: "rtsp://192.168.88.20:8554/file_01",
    enabled: true,
    position: 1
  },
  %{
    stream_id: "bbb",
    title: "通道 2: bbb",
    rtsp_url: "rtsp://192.168.88.20:8554/file_02",
    enabled: true,
    position: 2
  },
  %{
    stream_id: "ccc",
    title: "通道 3: ccc",
    rtsp_url: "rtsp://192.168.88.20:8554/file_03",
    enabled: true,
    position: 3
  }
]

Enum.each(initial_streams, fn attrs ->
  case Repo.get_by(Stream, stream_id: attrs.stream_id) do
    nil ->
      %Stream{}
      |> Stream.changeset(attrs)
      |> Repo.insert!()

    _stream ->
      :ok
  end
end)
