defmodule UrlHelper do
  def get_url_without_last_part(url) do
    uri = url |> URI.parse()
    new_path = _remove_suffix(uri.path)

    new_uri = %URI{
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: new_path
    }

    URI.to_string(new_uri)
  end

  defp _remove_suffix(path) do
    new_path =
      String.split(path, "/")
      |> List.delete_at(-1)
      |> Enum.join("/")

    if !String.ends_with?(new_path, "/") do
      new_path <> "/"
    end
  end

  def get_base_url(url) do
    uri = url |> URI.parse()

    new_uri = %URI{
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port
    }

    URI.to_string(new_uri)
  end

  def join(url, path) do
    url |> URI.parse |> URI.merge(path) |> URI.to_string()
  end
end
