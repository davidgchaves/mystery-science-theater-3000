defmodule MysteryScienceTheater_3000.PageController do
  use MysteryScienceTheater_3000.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
