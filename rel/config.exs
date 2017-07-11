# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"_2ChZ{k7yUXD|2b=2IOEyswL:c(oc)T7=USRn2DI>RK,_]kj1W!fQM8j^zj=.Rh4"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"4?q!m@mu<.}b9EuZ_6eX$gSA{)nn*&*AGLKsgLWG)s_Y8SL7<VWkP!WyjPJb5b?X"
  
  set pre_start_hook: "rel/hooks/pre_start.sh"
  set commands: [
    "ecto_create": "rel/commands/ecto_create.sh",
    "ecto_migrate": "rel/commands/ecto_migrate.sh"
  ]
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :a_math do
  set version: current_version(:a_math)
  set applications: [
    :runtime_tools
  ]
end
