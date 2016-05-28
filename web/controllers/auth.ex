defmodule MysteryScienceTheater_3000.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias MysteryScienceTheater_3000.User

  @moduledoc"""
  The MysteryScienceTheater.Auth plug:
    - processes the request information, and
    - transforms the conn, adding :current_user to conn.assigns
  """

  def init(opts), do: Keyword.fetch!(opts, :repo)

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    user = user_id && repo.get(User, user_id)

    assign conn, :current_user, user
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def login_by_username_and_password(conn, user, pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(User, username: user)

    cond do
      user && checkpw(pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end
end
