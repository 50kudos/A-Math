# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :a_math,
  ecto_repos: [AMath.Repo]

# Configures the endpoint
config :a_math, AMath.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JDtof2Du8rrIgU5+uav8gQU1Pa2lcm908zTiS5R3eBANY/Hd9O+p3jbBN6nDD+ws",
  render_errors: [view: AMath.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AMath.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
