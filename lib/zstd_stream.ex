defmodule ZstdStream do
  @moduledoc """
  Documentation for `ZstdStream`.
  """

  @doc """
  Decompress enumerable of zstd compressed bytes.

  See `:zstd.context/2` for available decompression parameters.
  """
  def decompress(enumerable, decompress_parameters \\ nil) do
    transform(enumerable, :decompress, Enum.into(decompress_parameters || [], %{}))
  end

  @doc """
  Compress enumerable of bytes.

  See `:zstd.context/2` for available compression parameters.
  """
  def compress(enumerable, compress_parameters \\ nil) do
    transform(enumerable, :compress, Enum.into(compress_parameters || [], %{}))
  end

  @doc false
  def transform(enumerable, mode, parameters) do
    start_fun = fn ->
      {:ok, dctx} = :zstd.context(mode, parameters)
      {dctx, ""}
    end

    next_fun = fn bytes, {dctx, rest} ->
      case :zstd.stream(dctx, [rest, bytes]) do
        {:continue, ""} -> {[], {dctx, ""}}
        {:continue, bin} -> {[bin], {dctx, ""}}
        {:continue, rest, ""} -> {[], {dctx, rest}}
        {:continue, rest, bin} -> {[bin], {dctx, rest}}
      end
    end

    last_fun = fn {dctx, rest} ->
      case :zstd.finish(dctx, rest) do
        {:done, [""]} -> {[], {dctx, ""}}
        {:done, iovec} -> {iovec, {dctx, ""}}
      end
    end

    after_fun = fn {dctx, ""} ->
      :zstd.close(dctx)
    end

    Stream.transform(enumerable, start_fun, next_fun, last_fun, after_fun)
  end
end
