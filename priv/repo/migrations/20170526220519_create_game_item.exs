defmodule AMath.Repo.Migrations.CreateAMath.Game.Item do
  use Ecto.Migration

  def change do
    create table(:game_items) do

      timestamps()
    end

  end
end
