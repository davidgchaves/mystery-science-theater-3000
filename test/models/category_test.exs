defmodule MysteryScienceTheater_3000.CategoryTest do
  use MysteryScienceTheater_3000.ModelCase

  alias MysteryScienceTheater_3000.Category

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Category.changeset(%Category{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Category.changeset(%Category{}, @invalid_attrs)
    refute changeset.valid?
  end
end
