defmodule CercleApi.Repo.Migrations.AddDueDateToCard do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :due_date, :utc_datetime
    end
  end
end
