use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mystery_science_theater_3000, MysteryScienceTheater_3000.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mystery_science_theater_3000, MysteryScienceTheater_3000.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "mystery_science_theater_3000_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
