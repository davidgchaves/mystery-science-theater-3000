ExUnit.start

Mix.Task.run "ecto.create", ~w(-r MysteryScienceTheater_3000.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r MysteryScienceTheater_3000.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(MysteryScienceTheater_3000.Repo)
