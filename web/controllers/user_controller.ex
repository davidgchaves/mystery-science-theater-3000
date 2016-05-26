defmodule MysteryScienceTheater_3000.UserController do
  use MysteryScienceTheater_3000.Web, :controller

  def index(conn, _params) do
    users = Repo.all(MysteryScienceTheater_3000.User)
    render conn, "index.html", users: users
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(MysteryScienceTheater_3000.User, id)
    render conn, "show.html", user: user
  end
end
