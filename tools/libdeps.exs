#!/usr/bin/env elixir
defmodule Libdeps do
  @relpath  "app/rel"
  @ertspath @relpath <> "/erts-7.0"
  @libpath  @relpath <> "/lib"
  @lddpath_regex ~r/\/(lib|usr\/lib)[^ ]+/

  def all_files do
    files
    |> Stream.flat_map(&ldd/1)
    |> Enum.uniq
    |> Enum.join(" ")
    |> IO.puts
  end

  defp files do
    executables ++ shared_libs
    |> Stream.uniq
    |> Stream.filter(fn(f)-> f != "" end)
  end

  defp executables do
    args = ~s(#{@relpath} -type f -perm -u+x) |> String.split
    {result, _} = System.cmd("find", args)
    clean_result(result)
  end

  defp shared_libs do
    args = ~s(#{@relpath} -type f -name *.so) |> String.split
    {result, _} = System.cmd("find", args)
    clean_result(result)
  end

  defp clean_result(result) do
    result
    |> String.strip
    |> String.split("\n")
  end



  defp ldd(file) do
    {result, _} = System.cmd("ldd", [file])
    Regex.scan(@lddpath_regex, result)
    |> Stream.map(fn([e, _])-> e end)
    |> Stream.uniq
    |> Stream.filter(fn(f)-> f != "" end)
    |> Stream.flat_map(&find_links/1)
    |> Enum.to_list
  end

  defp find_links(file) do
    Stream.unfold(file, &next_link/1) |> Enum.to_list
  end

  defp next_link(""),   do: nil
  defp next_link(file), do: {file, readlink(file)}

  defp readlink(file) do
    {result, _} = System.cmd("readlink", [file])
    result
    |> String.strip
    |> expand_path(file)
  end

  defp expand_path("", _relative_to), do: ""
  defp expand_path("/" <> _ = file, _relative_to), do: file
  defp expand_path(file, relative_to), do: Path.expand("../" <> file, relative_to)

  def debug(item) do
    IO.puts "item: #{inspect item, pretty: true}"
    item
  end
end

Libdeps.all_files
