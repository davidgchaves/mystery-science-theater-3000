defmodule MysteryScienceTheater_3000.Router do
  use MysteryScienceTheater_3000.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug MysteryScienceTheater_3000.Auth, repo: MysteryScienceTheater_3000.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MysteryScienceTheater_3000 do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    resources "/users",    UserController,    only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  scope "/manage", MysteryScienceTheater_3000 do
    pipe_through [:browser, :authenticate_user]

    resources "/videos", VideoController
  end

  # Other scopes may use custom stacks.
  # scope "/api", MysteryScienceTheater_3000 do
  #   pipe_through :api
  # end
end
