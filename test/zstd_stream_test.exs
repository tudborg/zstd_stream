defmodule ZstdStreamTest do
  use ExUnit.Case,
    async: true,
    parameterize:
      (for(
         data_fun <- [&Fixture.small/0, &Fixture.large/0],
         read_size <- [32, 1024, 64 * 1024],
         compression_level <- [-22, -1, 0, 1, 22]
       ) do
         %{data_fun: data_fun, read_size: read_size, compression_level: compression_level}
       end)

  doctest ZstdStream

  test "compress and decompress", %{
    data_fun: data_fun,
    read_size: read_size,
    compression_level: compression_level
  } do
    original_data = data_fun.()

    compressed_data =
      original_data
      |> Fixture.chunk(read_size)
      |> ZstdStream.compress(compressionLevel: compression_level)
      |> Enum.to_list()
      |> IO.iodata_to_binary()

    decompressed_data =
      compressed_data
      |> Fixture.chunk(read_size)
      |> ZstdStream.decompress()
      |> Enum.to_list()
      |> IO.iodata_to_binary()

    assert original_data == decompressed_data
  end
end
