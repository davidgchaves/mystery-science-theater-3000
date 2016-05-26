defmodule MysteryScienceTheater_3000.UserController do
  use MysteryScienceTheater_3000.Web, :controller

  def index(conn, _params) do
    users = Repo.all(MysteryScienceTheater_3000.User)
    render conn, "index.html", users: users
  end
end
