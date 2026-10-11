defmodule Web.Orm.Query.Settings do
  import Ecto.Query, warn: false
  alias Web.Repo
  alias Web.Orm.Entity.Setting

  def get_setting(key, default \\ nil) do
    case Repo.get_by(Setting, key: key) do
      nil -> default
      %Setting{value: nil} -> default
      %Setting{value: ""} -> default
      %Setting{value: value} -> value
    end
  end

  def set_setting(key, value) do
    case Repo.get_by(Setting, key: key) do
      nil ->
        %Setting{}
        |> Setting.changeset(%{key: key, value: to_string(value)})
        |> Repo.insert()

      setting ->
        setting
        |> Setting.changeset(%{value: to_string(value)})
        |> Repo.update()
    end
  end

  def get_gateway_url do
    get_setting("gateway_url")
  end

  def set_gateway_url(url) when is_binary(url) do
    trimmed = String.trim(url)

    cleaned =
      if String.starts_with?(trimmed, "http://") or String.starts_with?(trimmed, "https://") do
        trimmed
      else
        "http://" <> trimmed
      end
      |> String.trim_trailing("/")

    set_setting("gateway_url", cleaned)
  end

  def get_alert_callback_url do
    get_setting("alert_callback_url", "")
  end

  def set_alert_callback_url(url) when is_binary(url) do
    trimmed = String.trim(url)
    set_setting("alert_callback_url", trimmed)
  end

  def set_alert_callback_url(nil) do
    set_setting("alert_callback_url", "")
  end

  def get_alert_cooldown_sec do
    get_setting("alert_cooldown_sec", "1")
  end

  def set_alert_cooldown_sec(sec) do
    val = to_string(sec || "1") |> String.trim()
    set_setting("alert_cooldown_sec", if(val == "", do: "1", else: val))
  end

  def get_alert_timeout_sec do
    get_setting("alert_timeout_sec", "3")
  end

  def set_alert_timeout_sec(sec) do
    val = to_string(sec || "3") |> String.trim()
    set_setting("alert_timeout_sec", if(val == "", do: "3", else: val))
  end
end
