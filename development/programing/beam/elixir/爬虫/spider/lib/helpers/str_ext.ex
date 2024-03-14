defmodule StrExt do
  def sub_string_between_strings(full, start_str, end_str) do
    start_pos =
      case Kernel.byte_size(start_str) do
        0 ->
          0

        _ ->
          case :binary.match(full, start_str) do
            {index, length} ->
              index + length

            _ ->
              0
          end
      end

    binary_length =
      case Kernel.byte_size(end_str) do
        0 ->
          Kernel.byte_size(full) - start_pos

        _ ->
          case :binary.match(full, end_str) do
            {index, _length} ->
              index - start_pos

            _ ->
              Kernel.byte_size(full) - start_pos
          end
      end

    Kernel.binary_part(full, start_pos, binary_length)
  end

  def sub_string_before_string(full, spec_str) do
    case :binary.match(full, spec_str) do
      {index, _} ->
        Kernel.binary_part(full, 0, index)

      _ ->
        ""
    end
  end

  def sub_string_after_string(full, spec_str) do
    case :binary.match(full, spec_str) do
      {index, length} ->
        Kernel.binary_part(full, index + length, Kernel.byte_size(full) - index - length)

      _ ->
        ""
    end
  end
end
