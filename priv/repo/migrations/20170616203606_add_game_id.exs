defmodule AMath.Repo.Migrations.AddGameId do
  use Ecto.Migration

  def change do
    alter table(:game_items) do
      add :game_id, :string
    end
  end
end
