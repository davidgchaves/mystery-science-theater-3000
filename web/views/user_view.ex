defmodule MysteryScienceTheater_3000.UserView do
  use MysteryScienceTheater_3000.Web, :view
  alias MysteryScienceTheater_3000.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
end
