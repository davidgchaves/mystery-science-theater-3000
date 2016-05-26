defmodule MysteryScienceTheater_3000.Router do
  use MysteryScienceTheater_3000.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MysteryScienceTheater_3000 do
    pipe_through :browser # Use the default browser stack

    get "/users",     UserController, :index
    get "/users/:id", UserController, :show

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MysteryScienceTheater_3000 do
  #   pipe_through :api
  # end
end
