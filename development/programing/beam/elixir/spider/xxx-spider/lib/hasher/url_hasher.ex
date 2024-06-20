defmodule Hasher.UrlHasher do
  alias Hasher.RedisHasher

  def start_link(redis_host, redis_port, passwd, redis_db_number) do
    RedisHasher.start_link(redis_host, redis_port, passwd, redis_db_number)
  end

  def set_url_hash(url, content) do
    url_md5 = _make_md5(url)
    content_md5 = _make_md5(content)

    if url_md5 !== "" && content_md5 !== "" do
      hash_value = "#{url_md5}#{content_md5}"
      _set_hash(url, hash_value)
    end
  end

  def is_url_hash_need_update(url, content) do
    url_md5 = _make_md5(url)
    content_md5 = _make_md5(content)

    cond do
      url === "" or content === "" ->
        false

      !_is_url_hash_existed(url) ->
        true

      url_md5 !== "" && content_md5 !== "" ->
        old_hash_value = _get_hash(url)
        new_hash_value = "#{url_md5}#{content_md5}"

        if old_hash_value !== new_hash_value do
          true
        else
          false
        end

      true ->
        false
    end
  end

  defp _is_url_hash_existed(url) do
    case _get_hash(url) do
      nil ->
        false

      _ ->
        true
    end
  end

  defp _set_hash(url, hash_value) do
    GenServer.cast(RedisHasher, {:set_hash, {url, hash_value}})
  end

  defp _get_hash(url) do
    GenServer.call(RedisHasher, {:get_hash, url})
  end

  defp _make_md5(text) do
    case text do
      "" ->
        ""

      _ ->
        :crypto.hash(:md5, text) |> Base.encode16()
    end
  end
end
