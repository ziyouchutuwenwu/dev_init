defmodule TimeExt do
  def get_today() do
    {erl_date, _} = :calendar.local_time()
    {:ok, date} = Date.from_erl(erl_date)
    Calendar.strftime(date, "%c", preferred_datetime: "%Y-%m-%d")
  end

  def get_now_time() do
    {erl_date, erl_time} = :calendar.local_time()
    {:ok, date} = Date.from_erl(erl_date)
    date_str = Calendar.strftime(date, "%c", preferred_datetime: "%Y-%m-%d")

    {:ok, time} = Time.from_erl(erl_time)
    time_str = Calendar.strftime(time, "%c", preferred_datetime: "%H:%M:%S")
    "#{date_str} #{time_str}"
  end

  def ms_timestamp_to_str(ts) do
    ts
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_string()
  end
end
