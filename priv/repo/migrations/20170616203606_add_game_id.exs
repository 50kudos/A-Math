defmodule AMath.Repo.Migrations.AddGameId do
  use Ecto.Migration
  alias AMath.Game

  def change do
    alter table(:game_items) do
      add :game_id, :string
    end
  end
end
