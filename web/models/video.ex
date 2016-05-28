defmodule MysteryScienceTheater_3000.Video do
  use MysteryScienceTheater_3000.Web, :model

  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :user, MysteryScienceTheater_3000.User

    timestamps
  end

  @required_fields ~w(url title description)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
