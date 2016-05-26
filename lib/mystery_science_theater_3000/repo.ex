defmodule MysteryScienceTheater_3000.Repo do
  @moduledoc """
  In memory repository.
  """

  def all(MysteryScienceTheater_3000.User) do
    [%MysteryScienceTheater_3000.User{
       id: "1", name: "Andrei", username: "andreitarkovski", password: "solaris"},
     %MysteryScienceTheater_3000.User{
       id: "2", name: "Ingmar", username: "ingmarbergman", password: "persona"},
     %MysteryScienceTheater_3000.User{
       id: "3", name: "Jean-Luc", username: "jeanlucgodard", password: "loveskarina"}
    ]
  end
  def all(_module), do: []

  def get(module, id) do
    Enum.find all(module), fn map -> map.id == id end
  end

  def get_by(module, params) do
    Enum.find all(module), fn map ->
      Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
    end
  end
end
