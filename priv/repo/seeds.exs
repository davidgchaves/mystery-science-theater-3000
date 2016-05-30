# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MysteryScienceTheater_3000.Repo.insert!(%MysteryScienceTheater_3000.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias MysteryScienceTheater_3000.Category
alias MysteryScienceTheater_3000.Repo

for category <- ~w(Action Arthouse Comedy Drama Romance Sci-fi) do
    Repo.get_by(Category, name: category) || Repo.insert!(%Category{name: category})
end
