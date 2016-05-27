defmodule MysteryScienceTheater_3000.User do
  use MysteryScienceTheater_3000.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w{name username}, [])
    |> validate_length(:username, min: 1, max: 20)
  end
end
