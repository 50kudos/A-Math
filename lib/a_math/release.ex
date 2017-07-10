defmodule AMath.Release do

  def ecto_create do
    Application.load(:a_math)
    {:ok, _} = Application.ensure_all_started(:ecto)

    repos = Application.get_env(:a_math, :ecto_repos)

    Enum.each(repos, fn repo ->
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          IO.puts "created"
        {:error, :already_up} ->
          IO.puts "already created"
        {:error, term} ->
          raise "error: #{term}"
      end
    end)

    :init.stop()
  end

  def ecto_migrate do
    Application.load(:a_math)
    {:ok, _} = Application.ensure_all_started(:ecto)
    
    repos = Application.get_env(:a_math, :ecto_repos)

    Enum.each(repos, fn repo ->
      {:ok, _} = repo.__adapter__.ensure_all_started(repo, :temporary)
      {:ok, _} = repo.start_link(pool_size: 1)
    end)

    Enum.each(repos, fn repo ->
      path = Application.app_dir(:a_math, "priv/repo/migrations")

      Ecto.Migrator.run(repo, path, :up, all: true)
    end)

    :init.stop()
  end
end
