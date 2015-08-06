defmodule AppInfo do
  def name,    do: config |> Dict.get(:app)
  def version, do: config |> Dict.get(:version)
  def exrm,    do: deps |> Dict.has_key?(:exrm)
  def phoenix, do: deps |> Dict.has_key?(:phoenix)

  defp config, do: Mix.Project.config
  defp deps,   do: config |> Dict.get(:deps)
end
