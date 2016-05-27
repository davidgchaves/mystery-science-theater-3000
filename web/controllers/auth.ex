defmodule MysteryScienceTheater_3000.Auth do
  import Plug.Conn
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
end
