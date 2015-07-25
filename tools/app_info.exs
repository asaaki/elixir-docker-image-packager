defmodule AppInfo do
  def config, do: Mix.Project.config

  def app_name,    do: config |> Dict.get(:app)
  def app_version, do: config |> Dict.get(:version)
  def exrm,        do: config |> Dict.get(:deps) |> Dict.has_key?(:exrm)

  def as_env do
    "APPNAME=#{app_name} APPVER=#{app_version} EXRM=#{exrm}"
  end
end
