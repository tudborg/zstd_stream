defmodule Fixture do
  def small do
    "Hello, ZstdStream!"
  end

  def large do
    String.duplicate(:rand.bytes(1024), 1024 * 64)
  end

  def chunk(binary, chunk_size) do
    Stream.resource(
      fn -> binary end,
      fn
        <<>> -> {:halt, nil}
        <<chunk::binary-size(chunk_size), rest::binary>> -> {[chunk], rest}
        <<chunk::binary>> -> {[chunk], <<>>}
      end,
      fn _ -> :ok end
    )
  end
end
