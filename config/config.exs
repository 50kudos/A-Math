# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :a_math, ecto_repos: [AMath.Repo]

# Configures the endpoint
config :a_math, AMath.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bOkzilJWPhvhiu6tRBw2U0nVaDY1+TMnvzSURiQT1ydjHUrd+LktZNnqEu2h1Qqi",
  render_errors: [view: AMath.Web.ErrorView, accepts: ~w(html json)],
  pubsub_server: AMath.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
